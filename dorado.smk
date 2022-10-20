configfile: "d-test.yaml"

rule fast2pod:
    input:
        fast5_dir = "fast5s/{sample}/"
    output:
        pod5 = "pod5s/{sample}.pod5"
    log:
        "logs/fast2pod/{sample}.log"
    benchmark:
        "benchmarks/fast2pod/{sample}.txt"
    conda: "pod5"
    threads: 8
    shell:
        "pod5-convert-from-fast5 {input.fast5_dir}* {output.pod5}"

rule dorado:
    input: 
        pod5 = "pod5s/{sample}"
    output:
        unalign_sam = "dorado_output/{sample}.sam"
    params:
        model = config[]
    log: 
        "logs/dorado/{sample}.log"
    benchmark:
        "benchmarks/dorado/{sample}.txt"
    conda: "dorado"
    threads: 8 
    shell:
        "dorado basecaller {params.model} {input.pod5} > {output.unalign_sam}"

rule samtools_view:
    input:
        sam = "dorado_out/{sample}.sam"
    output:
        bam = "samtools_view/{sample}.bam"
    conda:
        "minimap"
    threads: 8
    log: 
        "logs/samtools_view/{sample}.log"
    shell:
        "samtools view -@7 -b -1 {input.sam} > {output.bam}"

rule pbmm2_index:
    output:
        ref_index = "pbmm2_index/ref.mmi"
    params:
        reference = config["reference"]
    conda:
        "pbmm2"
    log:
        "logs/pbmm2_index/ref.log"
    shell:
        "pbmm2 index {params.reference} {output.ref_index}"

rule align_bam: 
    input: 
        unalign_bam = "samtools_view/{sample}.bam",
        ref_index = "pbmm2_index/ref.mmi"
    output:
        sorted_bam = "pbmm2_output/{sample}.sorted.bam"
        bai = "pbmm2_output/{sample}.sorted.bam.bai"
    params:
        reference = config["reference"]
    conda:
        "pbmm2"
    log:
        "logs/pbmm2/{sample}.log"
    benchmark:
        "benchmarks/pbmm2/{sample}.txt"
    shell:
        "pbmm2 align {input.ref_index} {input.unalign_bam} {output.sorted_bam} --sort -j 4 -J 2"