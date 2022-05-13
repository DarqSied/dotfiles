//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
	/*Icon*/	        /*Command*/		/*Update Interval*/	/*Update Signal*/
	{"^c#f1fa8c^",    	"nettraf",	    5,	                0},
	{"^c#f8f8f2^",    	"internet",	    5,	                0},
	{"^c#ff79c6^",    	"cpu",  	    10,	                0},
	{"^c#ff5555^",    	"memory",	    10,	                0},
	{"^c#50fa7b^",    	"battery",	    5,	                0},
};

//sets delimeter between status commands. NULL character ('\0') means no delimeter.
static char delim[] = " | ";
static unsigned int delimLen = 5;
