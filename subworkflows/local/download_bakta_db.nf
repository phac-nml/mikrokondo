// Isolated workflow to aid the user in downloading a bakta DB

include { BAKTA_DB_DOWNLOAD } from '../../modules/local/bakta_download_db.nf'

workflow {

    main:
    BAKTA_DB_DOWNLOAD()

    emit:
    versions = BAKTA_DB_DOWNLOAD.out.versions
    db = BAKTA_DB_DOWNLOAD.out.versions

}
