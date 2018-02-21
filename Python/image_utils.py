import numpy as np
from scipy import misc
import matplotlib.pyplot as plt
import pandas as pd
from revoscalepy import RxSqlServerData, rx_data_step, rx_import

def show_img(img, title):
    photo_data = misc.imread(img)
    plt.figure(figsize=(4,4))
    plt.axis('off')
    plt.title(title, fontsize=20)
    plt.imshow(photo_data)

def submit_img(conn_str, table, img):
    inp = {'image': img, 'Label': 0}
    df = pd.DataFrame([inp], columns=inp.keys())
    out = RxSqlServerData(table=table, connection_string=conn_str)
    rx_data_step(input_data=df, output_file = out, overwrite=True)
    print("{} uploaded to {}".format(img, table))