#include "lime.h"


int write_vaddr_disk(void *, size_t);
int setup_disk(void);
void cleanup_disk(void);

static void disable_dio(void);

static struct file * f = NULL;
extern char * path;
extern int dio;

static void disable_dio() {
	DBG("Direct IO may not be supported on this file system. Retrying.");
	dio = 0;
	cleanup_disk();
	setup_disk();
}

int setup_disk() {
	mm_segment_t fs;
	int err;
	
	fs = get_fs();
	set_fs(KERNEL_DS);
	
	if (dio)	
		f = filp_open(path, O_WRONLY | O_CREAT | O_LARGEFILE | O_SYNC | O_DIRECT, 0444);
	
	if(!dio || (f == ERR_PTR(-EINVAL))) {
		DBG("Direct IO Disabled");
		f = filp_open(path, O_WRONLY | O_CREAT | O_LARGEFILE, 0444);
		dio = 0;
	}

	if (!f || IS_ERR(f)) {
		DBG("Error opening file %ld", PTR_ERR(f));
		set_fs(fs);
		err = (f) ? PTR_ERR(f) : -EIO;
		f = NULL;
		return err;
	}

	set_fs(fs);

	return 0;
}

void cleanup_disk() {
	mm_segment_t fs;
	
	fs = get_fs();
	set_fs(KERNEL_DS);
	if(f) filp_close(f, NULL);
	set_fs(fs);
}

int write_vaddr_disk(void * v, size_t is) {
	mm_segment_t fs;

	long s;

	fs = get_fs();
	set_fs(KERNEL_DS);
	    
	s = vfs_write(f, v, is, &f->f_pos);					
	
	set_fs(fs);

	if (s != is && dio) {
		disable_dio();
		return write_vaddr_disk(v, is);
	}

	return s;
}
