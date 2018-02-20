### Prepare Database do we need this??
--------------

We upload the images to SQL Server to simulate an scenario where the images for your solution are already in SQL Server.

The first step is to create a imagesbase called `ImageSimilarity` with FileTable enabled in SQL Server. Follow the instructions [here](https://docs.microsoft.com/en-us/sql/relational-imagesbases/blob/enable-the-prerequisites-for-filetable)
to set it up. Execute [create_imagesbase_with_filetable.sql](SQLPy/create_imagesbase_with_filetable.sql) to create the imagesbase and allow it to support FileTables. 

The power-shell script [run_image_similarity.ps1](SQLPy/run_image_similarity.ps1)
will create the imagesbase if the imagesbase does not exist. The power-shell script will create the FileTable as well. Or you could execute [create_file_table.sql](SQLPy/create_file_table.sql) to create a FileTable called `ImageStore` separately.

Once you create the FileTable in SQL Server, you will get the directory of the FileTable. You can then upload the images into the SQL FileTable by copying the images from the disk and pasting to the directory of FileTable `ImageStore`.  Here the directory of the FileTable is
`\\computer-name\MSSQLSERVER\FileTableimages\ImageStore`. In the power-shell script, we provide power-shell command to copy the image folders into the FileTable directory. Another way to upload the image to FileTable is to execute [copy_images_into_filetable.py](Python/copy_images_into_fileTable.py) to upload the images.