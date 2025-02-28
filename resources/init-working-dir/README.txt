NEXT STEPS BEFORE RUNNING MYBRAIN-SEQ

Please, complete the next steps before running myBrain-Seq analysis:

------------------------------------------------------------------------------

        1. Fill the "compi.parameters" file in thw working directory, e.g.:

                [...]
                # Absolute path to the working dir
                working_dir=/path/to/working/dir

                # Paths to input files and directories relatives to the working dir
                genome_fasta=genome/Homo_sapiens.GRCh38.dna.primary_assembly.fa
                reference_annotation=genes/Homo_sapiens.GRCh38.113.chr.gtf

==============================================================================

        2. Fill the "metadata.tsv" file in "samples/" directory, e.g.:

                sample	class	batch
                hcc1395_normal_rep1	normal	A
                hcc1395_normal_rep2	normal	A
                hcc1395_normal_rep3	normal	B
                hcc1395_tumor_rep2	tumor	B
                hcc1395_tumor_rep1	tumor	C
                hcc1395_tumor_rep3	tumor	C

==============================================================================

        3. Fill the "contrasts.tsv" file in "config/" directory, e.g.:

            reference	comparison
            normal	tumor

==============================================================================

        4. Run the analysis interactively by using the "run.sh" script 
            placed on the working-dir:

           - To start the analysis using the script adapt the following code:
                        ./run.sh /absolute/path/to/compi.parameters

        NOTE: to perform partial executions or change the number of parallel
        processes of the analysis, please consult the documentation.

------------------------------------------------------------------------------

For more information about these steps, please refeer to the online documentation
at: https://github.com/sing-group/compi-rnaseq-pipeline
