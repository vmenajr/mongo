#include <stdio.h>
#include <iostream>
#include <stdlib.h> 
#include <string.h> 


const char* flag = "xxxx";  

bool step1 = false;
bool step2 = false; 
bool step3 = false;

bool IsCrossSteam() {
	return step1 && step2 && step3;
}

void stone3(char* a) {
	if (strcmp(a, "yippie") == 0) {
		step3 = true;
	}
}

void stone2(double a) {
	if (a - 1337.1337 < .01) {
		step2 = true;
	}
}

void stone1(char a, char b, char c, char d) {
	if (a == '1' && b == '3' && c == '3' && d == '7') {
		step1 = true;
	}
}

void CrossStream() {
	printf("Stone 1 %p\n", stone1);
	printf("Stone 2 %p\n", stone2);
	printf("Stone 3 %p\n", stone3);

	printf("Good luck: ");

	char smasher[12];
   	std::cin >> smasher;
}

int main() {
	setbuf(stdout, NULL);

	CrossStream();

	printf("attempting to cross...\n");

	if (IsCrossSteam()) {
		printf("Nice work: %s\n", flag);
	} else {
		printf("you fell into the steam. try again.");
	}

	return 0;
}

