//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
	/*Icon*/	        /*Command*/		/*Update Interval*/	/*Update Signal*/
	{"^c#ff5555^",    	"nettraf",	    5,	                0},
	{"^c#f1fa8c^",    	"internet",	    5,	                0},
	{"^c#8be9fd^",    	"cpu",  	    10,	                0},
	{"^c#50fa7b^",    	"memory",	    10,	                0},
	{"^c#bd93f9^",    	"battery",	    10,	                0},
};

//sets delimeter between status commands. NULL character ('\0') means no delimeter.
static char delim[] = " | ";
static unsigned int delimLen = 5;
