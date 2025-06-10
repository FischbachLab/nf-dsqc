#!/usr/bin/env nextflow
import groovy.json.JsonOutput

nextflow.enable.dsl=2
include { SamplePreprocess_missed; SamplePreprocess_unmapped;} from './modules/ds_qc'
include { BLASTS_missed; BLASTS_unmapped;} from './modules/ds_qc'
include { SamplePostprocess_missed; SamplePostprocess_unmapped;} from './modules/ds_qc'
include { Report_missed; Report_unmapped;} from './modules/ds_qc'

// If the user uses the --help flag, print the help text below
params.help = false

// Function which prints help message text
def helpMessage() {
  log.info"""
    Reads post-processing pipeline for ninjaMap

    Required Arguments:
      --project  value    Folder to place analysis outputs (default: )
      --seedfile path     A csv file with headers in the format "Name,Bam"
      --db                db_name   NinjaMap database name
      --db_prefix         db_prefix NinjaMap database prefix
      --db_path           db_path   NinjaMap database path

    Options
      --blast_perc_identity  value   Minimum percent identity of matches to report in Blast (default:100)
      --bam_perc_identity    value   Minimum percent identity of matched to report in Bam (default:97)
      --outdir    path      Base directory for output files (default: )
      --tree  <true|false>  Optional whether a tree is built or not (default:false)
    """.stripIndent()
}

log.info"""Starting""".stripIndent()

// Show help message if the user specifies the --help flag at runtime
if (params.help) {
  // Invoke the function above which prints the help message
  helpMessage()
  // Exit out and do not run anything else
  exit 0
}

process printParams {

    container  params.docker_container_report
    publishDir "${params.outdir}/${params.project}/parameters/"

    errorStrategy = 'ignore'

    output:
    path "parameters.json"


    script:
    """
    touch parameters.json
    echo '${JsonOutput.toJson(params)}' > parameters.json
    """
}


workflow {
/*
   seedfile_ch = Channel
            .fromPath(params.seedfile)
            .ifEmpty { exit 1, "Cannot find any seed file matching: ${params.seedfile}." }
            .splitCsv(header: ['name', 'bam'], sep: ',')
            .map{ row -> tuple(row.name, row.bam)}


  seedfile_ch_unmapped = Channel
            .fromPath(params.seedfile)
            .ifEmpty { exit 1, "Cannot find any seed file matching: ${params.seedfile}." }
            .splitCsv(header: ['name', 'R1', 'R2'], sep: ',')
            .map{ row -> tuple(row.name, row.R1, row.R2)}
*/

  seedfile_ch_path = Channel
            .fromPath(params.seedfile)
            .ifEmpty { exit 1, "Cannot find any seed file matching: ${params.seedfile}." }
            .splitCsv(header: ['name', 'ninja'], sep: ',')
            .map{ row -> tuple(row.name, row.ninja)}

/*
  sample_name = Channel
            .fromPath(params.seedfile)
            .splitCsv(header: ['name', 'R1', 'R2'], sep: ',')
            .map{ row -> row.name }
            .toSortedList()
 */ 
    //seedfile_ch | SamplePreprocess

    
    seedfile_ch_path | SamplePreprocess_unmapped
    seedfile_ch_path | SamplePreprocess_missed

    //cat_reads(SamplePreprocess_unmapped.out.preprocess_out_ch2.join(SamplePreprocess_missed.out.preprocess_out_ch2))

    SamplePreprocess_unmapped.out.out_ch1 | BLASTS_unmapped
    SamplePreprocess_missed.out.out_ch1 | BLASTS_missed
 /*   
    BLASTS =Channel
    .fromPath("s3://genomics-workflow-core/Results/DSQC/20240419/02_blast/*.nt.tsv")
    .map { filepath -> tuple(filepath.name.tokenize('.')[0], filepath ) }
    
    sample_name2 = Channel
          .fromPath("s3://genomics-workflow-core/Results/DSQC/20240419/02_blast/*.nt.tsv")
          .map { filepath -> filepath.name.tokenize('.')[0] }
          .toSortedList()
   */ 
  //Channel
    //.fromPath("s3://genomics-workflow-core/Results/DSQC/20240311/01_preprocess/*/*_R*.fastq")
    //.map { filepath -> tuple(filepath.name.tokenize('.')[0], filepath ) }
  //SamplePostprocess(BLASTS.join(SamplePreprocess_unmapped.out.out_ch2))

    SamplePostprocess_unmapped(BLASTS_unmapped.out.BLASTS_out_ch.join(SamplePreprocess_unmapped.out.out_ch2))
    SamplePostprocess_missed(BLASTS_missed.out.BLASTS_out_ch.join(SamplePreprocess_missed.out.out_ch2))

    //SamplePostprocess(BLASTS.out.BLASTS_out_ch.join(SamplePreprocess_unmapped.out.preprocess_out_ch2))
    //SamplePostprocess(BLASTS_new.join(SamplePreprocess_unmapped.out.preprocess_out_ch2))

    Report_unmapped(SamplePostprocess_unmapped.out.postprocess_out_ch.toSortedList())     
    Report_missed( SamplePostprocess_missed.out.postprocess_out_ch.toSortedList())

    printParams()
}
