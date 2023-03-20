## matplotlib show chinese


-   import matplotlib.pyplot as plt \
-   plt.rcParams['font.sans-serif']=['SimHei'] #Show Chinese label \
-   plt.rcParams['axes.unicode_minus']=False   #These two lines need to be set manually \
-   copy ttf file to /venv/../matplotlib/mpl-data



$   plt.rcParams['font.sans-serif']=['SimHei'] #Show Chinese label
$   plt.rcParams['axes.unicode_minus']=False   #These two lines need to be set manually
$   cd ~/.cache/matplotlib
$   rm -rf *.*
