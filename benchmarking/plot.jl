using JSON
using Plots

path="./data"

resultFiles=sort([a for a in readdir(path) if endswith(a,".json")])

dataDict=Dict()

gatesList=[
    "X",
    "H",
    "T",
    "CNOT",
    "Y"
    ]


# specify labels for particular files. Filename is used by default.
labelsDict=Dict("dataYao_target=1"  => "Yao")

# add file names to list to ignore
ignoreList=[]

## specify color for particular files, otherwise next color in default cycle is used 
colorsDict=Dict(
    "dataYao_target=1"=>"#C71585",
)

# markerSize=20
linewidth=1.

gr(size=(1200,800), legend=false)

times_per_gate=Dict()
vectorQubits=nothing

firstPlotDict=Dict()

for gate in gatesList
    firstPlotDict[gate]=true
end


for fPath in resultFiles
    fName=split(fPath,".json")[1]

    if fName in ignoreList
        continue
    end

    println("Processing fileName: ",fName,".json")
    
    dataDict[fName]=JSON.parsefile(joinpath(path,fPath))

    for gate in gatesList

        if gate in keys(dataDict[fName])

            if firstPlotDict[gate]
                
                if vectorQubits == nothing
                    global vectorQubits=Vector{Float64}(dataDict[fName][gate]["nqubits"])
                end

                times_per_gate[gate]=Vector{Float64}(dataDict[fName][gate]["times"])
                
                
                if ~(fName in keys(labelsDict))
                    labelsDict[fName]=fName
                end

                # plotsPerGate[gate]=plot(
                #     dataDict[fName][gate]["nqubits"],
                #     dataDict[fName][gate]["times"],
                #     label=labelsDict[fName],
                #     linewidth=linewidth,
                #     yaxis=:log 
                #     )
                firstPlotDict[gate]=false

            else

                if length(dataDict[fName][gate]["times"]) ==  size(times_per_gate[gate],1)               
                    times_per_gate[gate]=hcat(
                        times_per_gate[gate],
                        Vector{Float64}(dataDict[fName][gate]["times"])
                        )

                    if ~(fName in keys(labelsDict))
                        labelsDict[fName]=fName
                    end
                else
                    println("Skipping $fName, wrong number of entries: ")
                    print("Should be: ",size(times_per_gate[gate],1))
                    println(" instead is: ",length(dataDict[fName][gate]["times"]))

                end
                # plotsPerGate[gate]=plot!(
                #     dataDict[fName][gate]["nqubits"],
                #     dataDict[fName][gate]["times"],
                #     label=labelsDict[fName],
                #     linewidth=linewidth,
                #     yaxis=:log 
                #     )
            end

            # colorsDict[fName]=line[0].get_c()
            # scatter!(
            #     dataDict[fName][gate]["nqubits"],
            #     dataDict[fName][gate]["times"],
            #     # color=colorsDict[fName],
            #     # s=markerSize
            #     )
        end
    end
end

plotList=[]
scatterList=[]

for gate in gatesList
    append!(plotList,[plot(
        vectorQubits,
        times_per_gate[gate],
        linewidth=linewidth,
        yaxis=:log 
        )]
    )

    append!(scatterList,[scatter!(
        vectorQubits,
        times_per_gate[gate],
        linewidth=linewidth,
        yaxis=:log 
        )]
    )
end

plot(
    plotList... ,
    # times_per_gate["H"],
    # times_per_gate["T"], 
    # times_per_gate["CNOT"], 
    # times_per_gate["Y"], 
    layout=(2,3)
)
