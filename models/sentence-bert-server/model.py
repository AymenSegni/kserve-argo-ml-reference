import json
import logging
from typing import Dict, List

import kserve
import torch
import torch.nn.functional as F
from kserve import InferOutput, InferRequest, InferResponse
from transformers import AutoModel, AutoTokenizer

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SentenceBERTServer(kserve.Model):
    def __init__(self, name: str):
        super().__init__(name)
        self.name = name
        self.ready = False
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model_name = "sentence-transformers/all-MiniLM-L6-v2"
        self.tokenizer = None
        self.model = None

    def load(self):
        logger.info(f"Loading {self.model_name} onto {self.device}")
        
        self.tokenizer = AutoTokenizer.from_pretrained(self.model_name)
        self.model = AutoModel.from_pretrained(self.model_name)
        self.model.to(self.device)
        self.model.eval()
        
        self.ready = True
        logger.info("Sentence-BERT model loaded successfully")

    def preprocess(self, payload: InferRequest, headers: Dict[str, str] = None) -> List[str]:
        logger.info("Received embedding request")
        
        inputs = payload.inputs[0]
        # Text input in data array
        texts = inputs.data
        return texts

    def predict(self, inputs: List[str], headers: Dict[str, str] = None) -> torch.Tensor:
        logger.info(f"Running inference for {len(inputs)} sentences")
        
        # Tokenize sentences
        encoded_input = self.tokenizer(
            inputs, padding=True, truncation=True, return_tensors='pt'
        ).to(self.device)

        # Compute token embeddings
        with torch.no_grad():
            model_output = self.model(**encoded_input)

        # Perform pooling (mean pooling)
        attention_mask = encoded_input['attention_mask']
        token_embeddings = model_output[0]
        input_mask_expanded = attention_mask.unsqueeze(-1).expand(token_embeddings.size()).float()
        
        sentence_embeddings = torch.sum(token_embeddings * input_mask_expanded, 1) / torch.clamp(input_mask_expanded.sum(1), min=1e-9)
        
        # L2 normalize embeddings
        sentence_embeddings = F.normalize(sentence_embeddings, p=2, dim=1)
            
        return sentence_embeddings

    def postprocess(self, result: torch.Tensor, headers: Dict[str, str] = None) -> InferResponse:
        logger.info("Formatting response")
        
        embeddings_list = result.cpu().numpy().tolist()
        
        # Derive shape from actual tensor (works for any embedding model)
        shape = list(result.shape)  # e.g. [batch_size, 384] or [batch_size, 768]
        
        # Flatten the list for output data
        flat_data = [item for sublist in embeddings_list for item in sublist]
        
        infer_output = InferOutput(
            name="embeddings",
            datatype="FP32",
            shape=shape,
            data=flat_data
        )
        
        return InferResponse(
            model_name=self.name,
            infer_outputs=[infer_output],
            response_id="1"
        )

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_name", default="sentence-bert")
    args = parser.parse_args()
    
    server = SentenceBERTServer(args.model_name)
    server.load()
    kserve.ModelServer().start([server])
