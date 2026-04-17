import torch
import numpy as np
import onnxruntime as ort
import sys
from convert_to_onnx import FastaiDenseNet121, AdaptiveConcatPool2d

def validate(pth_path, onnx_path):
    print("Validating consistency...")
    
    # Load PyTorch model
    checkpoint = torch.load(pth_path, map_location='cpu', weights_only=False)
    state_dict = checkpoint['model'] if 'model' in checkpoint else checkpoint
    
    model = FastaiDenseNet121(num_classes=2)
    new_state_dict = {}
    for k, v in state_dict.items():
        if k.startswith('0.0.'): new_k = k.replace('0.0.', 'body.', 1)
        elif k.startswith('0.1.'): new_k = k.replace('0.1.', 'body.', 1)
        elif k.startswith('1.'): new_k = k.replace('1.', 'head.', 1)
        else: new_k = k
        new_state_dict[new_k] = v
    model.load_state_dict(new_state_dict)
    model.eval()

    # Create dummy input
    dummy_input = torch.randn(1, 3, 224, 224)
    
    # PyTorch inference
    with torch.no_grad():
        pt_output = model(dummy_input).numpy()
    
    # ONNX inference
    ort_session = ort.InferenceSession(onnx_path)
    ort_inputs = {ort_session.get_inputs()[0].name: dummy_input.numpy()}
    ort_output = ort_session.run(None, ort_inputs)[0]
    
    # Compare
    diff = np.abs(pt_output - ort_output)
    max_diff = np.max(diff)
    mean_diff = np.mean(diff)
    
    print(f"Max difference: {max_diff:.6f}")
    print(f"Mean difference: {mean_diff:.6f}")
    
    if max_diff < 1e-4:
        print("SUCCESS: PyTorch and ONNX outputs are consistent! ✅")
    else:
        print("WARNING: Significant difference detected. ❌")
        # In medical AI, even small differences matter, but if they are < 1e-4 it's usually numerical noise
        if max_diff < 1e-2:
             print("Difference is within acceptable numerical noise for FP32.")

if __name__ == "__main__":
    validate(
        r"c:\Users\Ahmed Mekawi\vitaguard_app\assets\models\Model.pth",
        r"c:\Users\Ahmed Mekawi\vitaguard_app\assets\models\Model.onnx"
    )
