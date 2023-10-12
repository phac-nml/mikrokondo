/*A utility workflow for creating a mash sketch from the gtdb download

I am making alot of assumptions about what the user wants here, but over all this is a large process
to automate. With a lot of BIG files, so I am going to be slightly more stringent on how this
workflow is put together and either put the logic to create the inputs in a script entry point, or just leave it
to the user.

TODO have parameter for sketch size, perhaps bigger one would be more useful
TODO perhaps useful to remove redundant information in sequences to create a cleaner mash output
*/

include { MASH_SKETCH } from "../../modules/local/mash_sketch.nf"
include { MASH_PASTE } from "../../modules/local/mash_paste.nf"


workflow GTDBMash{

}
