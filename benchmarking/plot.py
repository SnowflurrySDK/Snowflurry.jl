from matplotlib import pyplot as plt
import json
import glob

path="benchmarking/data"

resultFiles=glob.glob(path+'/*.json')

dataDict={}

gatesList=[
    "X",
    "H",
    "T",
    "CNOT",
    "Y"
    ]

fig, axs = plt.subplots(2, 3,figsize=[12,8])

# specify labels for particular files. Filename is used by default.
labelsDict={
    "dataYao_target=1"              :"Yao",
}

# add file names to list to ignore
ignoreList=[]

## specify color for particular files, otherwise next color in default cycle is used 
colorsDict={
    "dataYao_target=1":"#C71585",
}

markerSize=20
linewidth=1.

resultFiles.sort()

for fPath in resultFiles:
    fName=fPath.split("/")[-1].replace(".json","")

    if fName in ignoreList:
        continue

    if fName not in labelsDict:
        labelsDict[fName]=fName

    print("fName: ",fName)

    with open(fPath,"r") as f:
        dataDict[fName]=json.load(f)

    for ax,gate in zip(axs.ravel(),gatesList):

        if gate in dataDict[fName].keys():
            if fName not in colorsDict.keys():
                line=ax.plot(
                    dataDict[fName][gate]["nqubits"],
                    dataDict[fName][gate]["times"],
                    label=labelsDict[fName],
                    linewidth=linewidth
                    )
            
                colorsDict[fName]=line[0].get_c()

            else:
                ax.plot(
                    dataDict[fName][gate]["nqubits"],
                    dataDict[fName][gate]["times"],
                    label=labelsDict[fName],
                    linewidth=linewidth,
                    color=colorsDict[fName],
                    )

            ax.scatter(
                dataDict[fName][gate]["nqubits"],
                dataDict[fName][gate]["times"],
                color=colorsDict[fName],
                s=markerSize
                )

            ax.set_yscale('log')
            ax.legend()
            ax.set_title("{} gate".format(gate))

            ax.grid("minor")

            ax.set_xlabel('n qubits')
            ax.set_ylabel('time (ns)')

plt.tight_layout()
plt.show()
