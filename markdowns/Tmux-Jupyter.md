# How to run Jupyter notebooks in the background using Tmux

***

Create a new session called "background-jupyter" using:

`tmux new-session -s background-jupyter`

Navigate to the directory containing all Jupyter notebooks intended for use. (Eg. FISH 546 - Bioinformatics is located in `/Users/calderatta/Desktop/FISH546_Bioinformatics`)

Launch Jupyter.

`jupyter notebook`

To exit back to main terminal session press "control-b", then "d".
