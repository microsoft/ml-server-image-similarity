#Tables
TABLE_IMAGES = 'dbo.ImageStore'
TABLE_TRAINING = 'dbo.training_images'
TABLE_TESTING = 'dbo.testing_images'
TABLE_RANKING = 'dbo.evaluation_images'
TABLE_SCORE = 'dbo.scores'
TABLE_QUERY = 'dbo.query_images'
TABLE_MODEL = 'dbo.model'
TABLE_RESULTS = 'dbo.ranking_results'
TABLE_FEATURE = 'dbo.features'
# Variables
PRETRAINED_DNN_MODEL = "Resnet18"
IMAGE_PIXEL = 224
MODEL_NAME = "rx_neural_net"
TOP_K_CANDIDATES = 10
ratioTrainTest = 0.75              # Percentage of images used for training classifier
maxQueryImgsPerSubdir  = 20        # Number of query images used to evaluate the classifier
maxNegImgsPerQueryImg  = 100       # Number of negative images per test query image

# Dimension of the DNN output
if PRETRAINED_DNN_MODEL.lower() == "resnet18":
    DNNOutputDimension = 512
elif PRETRAINED_DNN_MODEL.lower() == "resnet50":
    DNNOutputDimension = 2048
else:
    raise Exception("Model featurization dimension not specified.")
