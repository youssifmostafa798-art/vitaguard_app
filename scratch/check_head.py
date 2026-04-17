import torch

def check_head_keys(model_path):
    checkpoint = torch.load(model_path, map_location='cpu', weights_only=False)
    state_dict = checkpoint['model'] if 'model' in checkpoint else checkpoint
    
    print("Head Keys (prefix 1.):")
    for k in state_dict.keys():
        if k.startswith('1.'):
            print(f"{k} -> {state_dict[k].shape}")

if __name__ == "__main__":
    check_head_keys(r"c:\Users\Ahmed Mekawi\vitaguard_app\assets\models\Model.pth")
