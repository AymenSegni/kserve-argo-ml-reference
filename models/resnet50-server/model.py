import base64
import io
import json
import logging
from typing import Dict, List

import kserve
import torch
from PIL import Image
from kserve import InferOutput, InferRequest, InferResponse
from torchvision import models, transforms

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ResNet50Server(kserve.Model):
    def __init__(self, name: str):
        super().__init__(name)
        self.name = name
        self.ready = False
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model = None
        self.preprocess_transform = None
        self.categories = None

    def load(self):
        logger.info(f"Loading ResNet50 model onto {self.device}")
        
        # Load pre-trained model
        weights = models.ResNet50_Weights.DEFAULT
        self.model = models.resnet50(weights=weights)
        self.model.to(self.device)
        self.model.eval()
        
        # Setup image transforms
        self.preprocess_transform = weights.transforms()
        
        # Load ImageNet categories
        self.categories = weights.meta["categories"]
        
        self.ready = True
        logger.info("ResNet50 model loaded successfully")

    def preprocess(self, payload: InferRequest, headers: Dict[str, str] = None) -> List[torch.Tensor]:
        logger.info("Received prediction request")
        
        inputs = payload.inputs
        images = []
        
        for inp in inputs:
            # Assuming input is base64 encoded image bytes
            data = inp.data[0]
            if isinstance(data, str):
                image_bytes = base64.b64decode(data)
            else:
                image_bytes = data
                
            img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
            tensor = self.preprocess_transform(img).to(self.device)
            images.append(tensor)
            
        return images

    def predict(self, inputs: List[torch.Tensor], headers: Dict[str, str] = None) -> torch.Tensor:
        logger.info(f"Running inference on batch of {len(inputs)} images")
        
        # Batch images: [batch_size, C, H, W]
        batch = torch.stack(inputs)
        
        with torch.no_grad():
            outputs = self.model(batch)
            # Apply softmax across class dimension for ALL images in batch
            probabilities = torch.nn.functional.softmax(outputs, dim=1)
            
        return probabilities

    def postprocess(self, result: torch.Tensor, headers: Dict[str, str] = None) -> InferResponse:
        logger.info("Formatting response")
        
        batch_size = result.shape[0]
        all_predictions = []
        
        for b in range(batch_size):
            # Get top 5 predictions for each image
            top5_prob, top5_catid = torch.topk(result[b], 5)
            
            predictions = []
            for i in range(top5_prob.size(0)):
                predictions.append({
                    "label": self.categories[top5_catid[i]],
                    "probability": float(top5_prob[i]),
                    "class_id": int(top5_catid[i])
                })
            all_predictions.append(predictions)
            
        # Create V2 protocol response
        infer_output = InferOutput(
            name="predictions",
            datatype="BYTES",
            shape=[batch_size],
            data=[json.dumps(preds) for preds in all_predictions]
        )
        
        return InferResponse(
            model_name=self.name,
            infer_outputs=[infer_output],
            response_id="1"
        )

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_name", default="resnet50")
    args = parser.parse_args()
    
    server = ResNet50Server(args.model_name)
    server.load()
    kserve.ModelServer().start([server])
