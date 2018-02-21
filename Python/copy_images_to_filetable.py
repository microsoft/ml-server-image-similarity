from image_similarity.image_similarity_utils import get_directories_in_directory
from image_similarity.image_similarity_utils import copy_image_to_filetable
import os

def insert_images_to_filetable(imgDir, filetable_dir):
    subdirs = get_directories_in_directory(imgDir)
    for subdir in subdirs:
        imagedir = os.path.join(imgDir, subdir)
        image_filetable_folder = os.path.join(filetable_dir, subdir)
        copy_image_to_filetable(imagedir, image_filetable_folder)


if __name__ == "__main__":
    print("----------------------------------------------------------------------------------")
    print("Insert images into SQL FileTable...")
    # this should be changed to your FileTable directory
    filetable_dir = "\\\\DESKTOP-QIONG\\MSSQLSERVER\\FileTableData\\ImageStore"
    # this is the disk directory of the image files, you should change it to the location of your image files
    imgDir = "E:/WorkSpace/SolutionTemplates/ImageSimilarity_SQL_Python/data/fashionTexture/"
    insert_images_to_filetable(imgDir, filetable_dir)
    print("Successfully insert images into SQL FileTable.")
    print("DONE.")
    print("--------------------------------------------------------------------------------------")