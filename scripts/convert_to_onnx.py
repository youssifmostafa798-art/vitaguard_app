"""Module for Convert To Onnx."""

from collections import OrderedDict
import onnx
import torch
import torch.nn as nn
import torchvision.models as models

# ONNX-friendly AdaptiveConcatPool2d
class AdaptiveConcatPool2d(nn.Module):
    """AdaptiveConcatPool2d class."""
    def __init__(self, sz=1):
        """Init."""
        super().__init__()
        # For 224x224 input, DenseNet features are 7x7.
        # Using MaxPool2d(7) instead of AdaptiveMaxPool2d(1) to avoid ONNX export issues.
        self.ap = nn.AvgPool2d(7)
        self.mp = nn.MaxPool2d(7)
    def forward(self, x):
        """Forward."""
        # Check if shape is not 7x7, then fallback to adaptive (safety)
        # However, for ONNX export, we want fixed paths if possible
        ap_out = self.ap(x)
        mp_out = self.mp(x)
        return torch.cat([ap_out, mp_out], dim=1)

class FastaiDenseNet121(nn.Module):
    """FastaiDenseNet121 class."""
    def __init__(self, num_classes=2):
        """Init."""
        super().__init__()
        original_densenet = models.densenet121(weights=None)
        self.body = original_densenet.features

        self.head = nn.Sequential(
            AdaptiveConcatPool2d(),
            nn.Flatten(),
            nn.BatchNorm1d(2048),
            nn.Dropout(p=0.25),
            nn.Linear(2048, 512, bias=False),
            nn.ReLU(inplace=True),
            nn.BatchNorm1d(512),
            nn.Dropout(p=0.5),
            nn.Linear(512, num_classes, bias=False)
        )

    def forward(self, x):
        """Forward."""
        x = self.body(x)
        x = self.head(x)
        return x

def convert(model_path, output_path):
    """Convert."""
    print(f"Loading weights from {model_path}...")
    checkpoint = torch.load(model_path, map_location='cpu', weights_only=False)
    state_dict = checkpoint['model'] if 'model' in checkpoint else checkpoint

    model = FastaiDenseNet121(num_classes=2)
    # The weight mapping remains the same as AdaptiveMaxPool doesn't have weights
    new_state_dict = OrderedDict()
    for k, v in state_dict.items():
        if k.startswith('0.0.'):
            new_k = k.replace('0.0.', 'body.', 1)
        elif k.startswith('0.1.'):
            new_k = k.replace('0.1.', 'body.', 1)
        elif k.startswith('1.'):
            new_k = k.replace('1.', 'head.', 1)
        else:
            new_k = k
        new_state_dict[new_k] = v

    model.load_state_dict(new_state_dict, strict=True)
    model.eval()
    print("Weights loaded successfully.")

    # We use dynamo=False if supported, or just hope the fixed pooling works
    dummy_input = torch.randn(1, 3, 224, 224)
    print(f"Exporting model to {output_path}...")
    torch.onnx.export(
        model,
        dummy_input,
        output_path,
        export_params=True,
        opset_version=18, # Use a modern opset
        do_constant_folding=True,
        input_names=['input'],
        output_names=['output'],
        # Ensure we don't use external data
        # some versions of torch split if model is 'large', but 32MB is small.
    )
    print("Consolidating into a single file...")
    onnx_model = onnx.load(output_path)
    # This will save everything into one file if it's < 2GB
    onnx.save_model(onnx_model, output_path, save_as_external_data=False)
    print("Consolidation successful.")

if __name__ == "__main__":
    convert(
        r"c:\Users\Ahmed Mekawi\vitaguard_app\assets\models\Model.pth",
        r"c:\Users\Ahmed Mekawi\vitaguard_app\assets\models\Model.onnx"
    )
