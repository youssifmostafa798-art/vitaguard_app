import tensorflow as tf
import sys

model_path = r'assets/models/model.tflite'

try:
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    
    inp = interpreter.get_input_details()
    out = interpreter.get_output_details()
    
    print("=== INPUT TENSORS ===")
    for i in inp:
        print(f"  index={i['index']} name={i['name']} shape={i['shape']} dtype={i['dtype']}")
    
    print("=== OUTPUT TENSORS ===")
    for o in out:
        print(f"  index={o['index']} name={o['name']} shape={o['shape']} dtype={o['dtype']}")

except ImportError:
    print("TensorFlow not found. Trying tflite_runtime...")
    try:
        import tflite_runtime.interpreter as tflite
        interpreter = tflite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        print("INPUT:", interpreter.get_input_details())
        print("OUTPUT:", interpreter.get_output_details())
    except ImportError:
        print("ERROR: Neither tensorflow nor tflite_runtime is installed.")
        print("Run: pip install tensorflow")
        sys.exit(1)
