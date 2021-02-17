/* 
 REACTION TIME GAME v 1.0
 Adapted by code made by Elaine Laguerta  
 by Luis Andrés Gonzalez, January 2016
 
 Reads reaction time from Arduino over the serial port and save it to .csv file on your computer.
 The .csv file will be saved in the same folder as your Processing sketch.
 This sketch assumes that values read in seconds by Arduino are separated by a newline character.
 Special code numbers are specified to signal the game start, success and failure of accomplishing the task. 
 Each reading will have it's own row and timestamp in the resulting csv file. This sketch will write a new file each day.   
 
 The hardware:
 * A pushbutton connected to Arduino input pins
 * Arduino connected to computer via USB cord
 
 The software:
 *Arduino IDE
 *Processing (download the Processing software here: https://www.processing.org/download/
 *The corresponding arduino code
 
 */

import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;

Serial myPort; //creates a software serial port on which you will listen to Arduino
Table table; //table where we will read in and store values. You can name it something more creative!

int numReadings = 1; //keeps track of how many readings you'd like to take before writing the file. 
int readingCounter = 0; //counts each reading to compare to numReadings. 

// Serial code numbers for specific events
int startCode = 9090; // code for game start
int earlyCode = 1010; // code for early button press
int lateCode = 7777; // code for late button press
String fillColor;
char letter;
String fileName;
String words;

void setup() {
  String portName = Serial.list()[1]; 
  //CAUTION: your Arduino port number is probably different! Mine happened to be 1. Use a "handshake" sketch to figure out and test which port number your Arduino is talking on. A "handshake" establishes that Arduino and Processing are listening/talking on the same port.
  //Here's a link to a basic handshake tutorial: https://processing.org/tutorials/overview/

  // SOUND setup:
  minim = new Minim(this);
  out = minim.getLineOut();
  out.setTempo( 80 );
  out.pauseNotes();
  // end SOUND setup.

  myPort = new Serial(this, portName, 9600); //set up your port to listen to the serial port

  table = new Table(); 
  table.addColumn("id"); //This column stores a unique identifier for each record. We will just count up from 0 - so your first reading will be ID 0, your second will be ID 1, etc. 

  //the following adds columns for time. You can also add milliseconds. See the Time/Date functions for Processing: https://www.processing.org/reference/ 
  table.addColumn("year");
  table.addColumn("month");
  table.addColumn("day");
  table.addColumn("hour");
  table.addColumn("minute");
  table.addColumn("second");

  //the following are dummy columns for each data value. Add as many columns as you have data values. Customize the names as needed. Make sure they are in the same order as the order that Arduino is sending them!
  table.addColumn("sensor1");
}

void serialEvent(Serial myPort) {

  String val = myPort.readStringUntil('\n'); //The newline separator separates each Arduino loop. We will parse the data by each newline separator. 

  if (val!= null) { //We have a reading! Record it.

    val = trim(val); //gets rid of any whitespace or Unicode nonbreakable space

    if (float(val) == startCode) {
      out.playNote( 0.0, 0.4, "C3" );
      out.playNote( 0.2, 0.2, "C4" );
      out.resumeNotes();
      fillColor="green";
    } else if (float(val) == earlyCode) {
      println("You pressed the button too early!");
      fillColor="red";
      out.playNote( 0, 2, "A1");
      out.resumeNotes();
    } else if (float(val) == lateCode) {
      println("You pressed the button too late!");
      fillColor="red";
      out.playNote( 0, 2, "A1");
      out.resumeNotes();
    } else {
      print("Your reaction time was: ");
      println(val); 
      out.playNote( 0, 0.2, "C4");
      out.playNote( 0.2, 0.2, "C4");
      out.playNote( 0.4, 0.2, "C4");
      out.resumeNotes();
      fillColor="yellow";
    } 

    float sensorVal = float(val); //parses the packet from Arduino and places the valeus into the sensorVals array. I am assuming floats. Change the data type to match the datatype coming from Arduino. 
    //if (Float.isNaN(float(val))) {
    if (sensorVal != startCode && !Float.isNaN(sensorVal) ) { // avoids start code to get recorded
      TableRow newRow = table.addRow(); //add a row for this new reading
      newRow.setInt("id", table.lastRowIndex());//record a unique identifier (the row's index)

      //record time stamp
      newRow.setInt("year", year());
      newRow.setInt("month", month());
      newRow.setInt("day", day());
      newRow.setInt("hour", hour());
      newRow.setInt("minute", minute());
      newRow.setInt("second", second());

      //record sensor information. Customize the names so they match your sensor column names. 

      if (sensorVal == earlyCode) {
        newRow.setString("sensor1", "early");
      } else if (sensorVal == lateCode) {
        newRow.setString("sensor1", "late");
      } else if (Float.isNaN(sensorVal)) {
      } else {
        newRow.setFloat("sensor1", sensorVal);
      }

      readingCounter++; //optional, use if you'd like to write your file every numReadings reading cycles
    }
    //saves the table as a csv in the same folder as the sketch every numReadings. 
    if (readingCounter % numReadings ==0) {//The % is a modulus, a math operator that signifies remainder after division. The if statement checks if readingCounter is a multiple of numReadings (the remainder of readingCounter/numReadings is 0)
      fileName = "data/" + str(year()) + str(month()) + str(day()) /*+" - " + str(table.lastRowIndex())*/ + ".csv"; //this filename is of the form year+month+day+readingCounter
      saveTable(table, fileName); //Woo! save it to your computer. It is ready for all your spreadsheet dreams.
    }
  }
}

void draw()
{ 
  //visualize your sensor data in real time here! In the future we hope to add some cool and useful graphic displays that can be tuned to different ranges of values.
  if (fillColor == "red") {              // If the serial value is 0,
    fill(255, 0, 0);                   // set fill to black
  } else if (fillColor == "green") {                       // If the serial value is not 0,
    fill(0, 255, 0);                 // set fill to light gray
  } else if (fillColor =="yellow") {
    fill(255, 255, 0);
  }
  rect(0, 0, 99, 99);
}

void keyTyped() {
  // The variable "key" always contains the value 
  // of the most recent key pressed.
  if ((key >= '0' && key <= '3') || key == ' ') {
    letter = key;
    words = words + key;
    // Write the letter to the console
    myPort.write(key);
  }
}