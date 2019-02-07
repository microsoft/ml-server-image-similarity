import os
import pandas as pd
import urllib.request

def download_and_place(type, link, data_dir, index):
    print("Downloading: type: {0}, link: {1}, data_dir: {2}, index: {3}".format(type,link,data_dir,index))
    if not os.path.exists(os.path.join(data_dir, type)):
        os.makedirs(os.path.join(data_dir, type))

    dstPath = os.path.join(data_dir, type, str(index) + ".jpg")
    if os.path.isfile(dstPath):
        print("Already downloaded image: " + link)
    else:
        try:
            urllib.request.urlretrieve(link, dstPath)
            #img = imread(dstPath)
            #assert(img is not None) # test if image was loaded correctly
            #print("Downloaded image {:4}: {}".format(index, link))
        except:
            if os.path.exists(dstPath):
                os.remove(dstPath)
            return 0
    return 1



def download_all(imgUrlFile, dstDataLoc):
    urls = pd.read_table(imgUrlFile, names=["type", "link"])
    count = 0
    for index, row in urls.iterrows():
        count = count + download_and_place(row.type, row.link, dstDataLoc, index)
        if (count % 10 == 0):
            print("downloaded {} images.".format(count))
    print("Downloaded {} images.".format(count))


if __name__ == "__main__":
    download_all("../data/fashion_texture_urls.tsv","../data")
    print("Downloaded all images. Moving to the next step.")