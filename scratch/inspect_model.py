import torch

def detailed_inspect(model_path):
    checkpoint = torch.load(model_path, map_location='cpu', weights_only=False)
    state_dict = checkpoint['model'] if 'model' in checkpoint else checkpoint
    
    print("Full Key List Summary:")
    keys = list(state_dict.keys())
    print(f"Total keys: {len(keys)}")
    
    # Analyze common prefixes
    prefixes = set()
    for k in keys:
        parts = k.split('.')
        if len(parts) > 1:
            prefixes.add(parts[0])
    print(f"Top-level prefixes: {prefixes}")

    # Check the very last layer to find num_classes
    last_keys = keys[-10:]
    for lk in reversed(last_keys):
        if 'weight' in lk or 'bias' in lk:
            shape = state_dict[lk].shape
            print(f"Potential output layer: {lk} with shape {shape}")

    # Inspect a few feature keys to see if they match standard architectures
    for k in keys:
        if 'conv' in k and 'weight' in k:
            print(f"Sample weight key: {k} with shape {state_dict[k].shape}")
            break

if __name__ == "__main__":
    detailed_inspect(r"c:\Users\Ahmed Mekawi\vitaguard_app\assets\models\Model.pth")
