package fr.kensa.dfpwmconverter;

import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.UnsupportedAudioFileException;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

public class Main {
    public static void main(String[] args) throws UnsupportedAudioFileException, IOException {
        if(args.length < 2){
            System.out.println("Usage: java -jar dfpwmconverter.jar <input file> <output file> [sample rate]");
            System.exit(1);
        }
        int sampleRate = 48000;
        if(args.length == 3) {
            sampleRate = Integer.parseInt(args[2]);
        }
        convert(args[0], args[1],sampleRate);
    }
    public static void convert(String inputFilename, String outputFilename,int sampleRate) throws UnsupportedAudioFileException, IOException {
        AudioFormat convertFormat = new AudioFormat(AudioFormat.Encoding.PCM_SIGNED, sampleRate, 8, 1, 1, sampleRate, false);
        AudioInputStream unconverted = AudioSystem.getAudioInputStream(new File(inputFilename));
        AudioInputStream inFile = AudioSystem.getAudioInputStream(convertFormat, unconverted);
        BufferedOutputStream outFile = new BufferedOutputStream(new FileOutputStream(outputFilename));

        byte[] readBuffer = new byte[1024];
        byte[] outBuffer = new byte[readBuffer.length / 8];
        DFPWM converter = new DFPWM(true);

        int read;
        do {
            for(read = 0; read < readBuffer.length;) {
                int amt = inFile.read(readBuffer, read, readBuffer.length - read);
                if(amt == -1) break;
                read += amt;
            }
            read &= ~0x07;
            converter.compress(outBuffer, readBuffer, 0, 0, read / 8);
            outFile.write(outBuffer, 0, read / 8);
        } while(read == readBuffer.length);
        outFile.close();
    }
}
