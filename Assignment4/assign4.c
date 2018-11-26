/*
CSC230 - Assignment 4
By: Jordan (Yu-Lin) Wang
V00786970
Stop Watch in C
*/

#include "CSC230.h"
#include <string.h> 

#define  ADC_BTN_RIGHT 0x032 //50
#define  ADC_BTN_UP 0x0C3 //195
#define  ADC_BTN_DOWN 0x17C //380
#define  ADC_BTN_LEFT 0x22B //555
#define  ADC_BTN_SELECT 0x316 //790

char Timer[100];
char Lap_Timer[100];
char Message;

int Ignore = 0;
int interrupt_count = 0;
int interrupt_increment= 10;

int Laps = 0;
int Lap_tenth;
int Lap_second_1;
int Lap_second_2;
int Lap_minute_1;
int Lap_minute_2;

int tenth = 0;
int second_1 = 0;
int second_2 = 0;
int minute_1 = 0;
int minute_2 = 0;

void Increment_Time() {
	
	tenth++;
	
	if (tenth == 10){
		second_1++;
		tenth = 0;
	} 
	if (second_1 == 10){
		second_2++;
		second_1 = 0;
	}
	if (second_2 == 6){
		minute_1++;
		second_2 = 0;
	}
	if (minute_1 == 10){
		minute_2++;
		minute_1 = 0;
	}
	if (minute_2 == 10){
		tenth = 0;
		second_2 = 0;
		second_1 = 0;
		minute_2 = 0;
		minute_1 = 0;
	}

}

// timer0_setup()
// Set the control registers for timer 0 to enable
// the overflow interrupt and set a prescaler of 1024.
void timer0_setup(){
	TIMSK0 = 0x01;
	TCNT0 = 0x00;
	TCCR0A = 0x00;
	TCCR0B = 0x05;
}

ISR(TIMER0_OVF_vect){

	interrupt_count = interrupt_count + interrupt_increment;

	if (interrupt_count >= 61){
		interrupt_count -= 61;
	}

	if (interrupt_count == 6){
		Increment_Time();
	} else if (interrupt_count == 12){
		Increment_Time();
	} else if (interrupt_count == 18){
		Increment_Time();
	} else if (interrupt_count == 24){
		Increment_Time();
	} else if (interrupt_count == 30){
		Increment_Time();
	} else if (interrupt_count == 36){
		Increment_Time();
	} else if (interrupt_count == 42){
		Increment_Time();
	} else if (interrupt_count == 48){
		Increment_Time();
	} else if (interrupt_count == 54){
		Increment_Time();
	} else if (interrupt_count == 60){
		Increment_Time();
	}
}

unsigned short poll_adc(){

	unsigned short adc_result = 0; //16 bits
	
	ADCSRA |= 0x40;
	while((ADCSRA & 0x40) == 0x40); //Busy-wait
	
	unsigned short result_low = ADCL;
	unsigned short result_high = ADCH;
	
	adc_result = (result_high<<8)|result_low;
	
	if (adc_result >= 0x00 && adc_result < ADC_BTN_RIGHT){
		Reset_Ignore_Button();
	} else if (adc_result >= ADC_BTN_RIGHT && adc_result < ADC_BTN_UP){
		Up_Button();
	} else if (adc_result >= ADC_BTN_UP && adc_result < ADC_BTN_DOWN){
		Down_Button();
	} else if (adc_result >= ADC_BTN_DOWN && adc_result < ADC_BTN_LEFT){
		Left_Button();
	} else if (adc_result >= ADC_BTN_LEFT && adc_result < ADC_BTN_SELECT){
		Select_Button();
	} else {
		Reset_Ignore_Button();
	}

}

//pause and unpause stop watch 
void Select_Button(){

	if (Ignore == 1){
		return; 
	}
	if (interrupt_increment == 0){
		interrupt_increment = 1;
	} else if (interrupt_increment == 1){
		interrupt_increment = 0;
	} 

	Ignore_Button();

}

void Ignore_Button(){
	Ignore = 1; 		
} 
void Reset_Ignore_Button(){
	Ignore = 0;
}

//set stop watch to 00:00.0 and pause
void Left_Button(){

	tenth = 0;
	second_1 = 0;
	second_2 = 0;
	minute_1 = 0;
	minute_2 = 0;
	interrupt_increment = 0;

}

void Up_Button(){
	
	if(Ignore == 1) {
	} else {		
		sprintf(Lap_Timer, "%d%d:%d%d.%d", Lap_minute_2, Lap_minute_1, Lap_second_2, Lap_second_1, Lap_tenth);
		lcd_xy( 0, 1 );
		lcd_puts(Lap_Timer);
	
		Lap_tenth = tenth;
		Lap_second_1 = second_1;
		Lap_second_2 = second_2;
		Lap_minute_1 = minute_1;
		Lap_minute_2 = minute_2; 

		sprintf(Lap_Timer, "%d%d:%d%d.%d", minute_2, minute_1, second_2, second_1, tenth);
		lcd_xy( 9, 1 );
		lcd_puts(Lap_Timer);
		Ignore = 1;
	}	


	 
}

void Down_Button(){
		sprintf(Lap_Timer, "       ", 0);
		lcd_xy( 0, 1 );
		lcd_puts(Lap_Timer);
	
		Lap_tenth = 0;
		Lap_second_1 = 0;
		Lap_second_2 = 0;
		Lap_minute_1 = 0;
		Lap_minute_2 = 0; 

		sprintf(Lap_Timer, "       ", 0);
		lcd_xy( 9, 1 );
		lcd_puts(Lap_Timer);
}
	
int main(){

	DDRB = 0xff;
	ADCSRA = 0x87;
	ADMUX = 0x40;

	//Enable interrupts
	timer0_setup();
	lcd_init();
	sei();

	while(1){
		unsigned short adc_result = poll_adc();
		sprintf(Timer, "Time: %d%d:%d%d.%d", minute_2, minute_1, second_2, second_1, tenth);
		lcd_xy( 0, 0 );
		lcd_puts(Timer);
	}

}

