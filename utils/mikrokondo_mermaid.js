flowchart LR
    CI(Check input):::lightGreen --> R((Reads));
    CI --> A((Assembly));
    R --> CA(CleanAssemble):::pink;
    CA --> QC(QC reads / clean reads):::lightGreen;
    QC --> QC1("Remove contaminants<br>(Minimap2)"):::orange;
    QC1 --> QC2(Fastp):::orange;
    QC2 --> QC3(parse Fastp<br>trimming):::orange;
    QC3 --> QC4("estimate coverage<br>(kat_hist)"):::orange;
    QC4 --> QC5("Subsample<br>(seqTK_sample)"):::orange;
    QC5 --> QC6("Contamination check<br>(Mash screen)"):::orange;
    QC6 --> QC7("Separate reads<br>(parse Mash)"):::orange;
    QC --> SR((short read));
    SR --> I((Isolate));
    SR --> M((Metagenomic));
    I --> AR(Assemble reads):::lightGreen;
    AR --> AR1(Bandage image):::orange;
    AR1 --> AR2((Illumina));
    AR2 --> AR22(Spades assemble):::orange;
    AR1 --> AR3((Pacbio/nanopore));
    AR3 --> AR32(Flye assemble):::orange;
    AR22 --> HAD3;
    AR32 --> HAD3;
    M -->|"set assembly flag<br>to `metagenomic`"| AR;
    QC --> H((Long read<br>or hybrid));
    H --> HA(Hybrid assembly):::lightGreen;
    HA --> HAD((Default));
    HAD --> HAD1(Flye assemble):::orange;
    HAD1 --> HAD2(Bandage image):::orange;
    HAD2 --> HAD3("Create contig index<br>(Minimap2 index)"):::orange;
    HAD3 --> HAD4("Generate SAM<br>(Minimap2 map)"):::orange;
    HAD4 --> HAD5(Racon polish):::orange;
    HAD5 --> HAD6(Pilon interate):::orange;
    HA --> HAU((Unicycler));
    HAU --> HAU1(Unicycler assemble):::orange;
    HAU1 --> HAU2(Bandage image):::orange;
    QC7 --> PA(Polish assemblies):::lightGreen;
    HAD6 --> PA;
    HAU2 --> PA;
    PA --> PAI((Illumina));
    PAI --> PAI1(Pilon iterate):::orange;
    PA --> PAN((Pacbio/nanopore));
    PAN --> PAN1(Medaka polish):::orange;
    PAI1 --> PASS(Post assembly):::pink;
    PAN1 --> PASS;
    A --> PASS;
    PASS --> I1((Isolate));
    PASS --> M1((Metagenomic));
    I1 --> QCA(QC assemblies):::lightGreen;


    subgraph legend [Legend]
    direction LR;
    wk(Workflow):::pink --> sw(Subworkflow):::lightGreen;
    sw --> m(Module):::orange;
    d((Decision));
    end






    classDef lightGreen fill:#0ABC9B,stroke:#0ABC9B,stroke-width:2px,rx:10px,ry:10px;
    classDef pink fill:#F681CB,stroke:#F681CB,stroke-width:2px,rx:10px,ry:10px;
    classDef orange fill:#F2B581,stroke:#F2B581,stroke-width:2px,rx:10px,ry:10px;
