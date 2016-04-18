package scrabble;

import java.io.*;
import java.util.*;



public class Scrabble {
	
	static List<Map<Character, Integer>> mappedWordList = new ArrayList<Map<Character,Integer>>();
	static List<String> wordList = new ArrayList<String>();
	
	public static void main(String[] args) {
		processWords();
		
		Scanner scan = new Scanner(System.in);
		
	    String input = "";
	    String bestWord = "";
	    int bestVal;
	    
	    // Input loop
	    while (true) {
	    	System.out.print("Enter your scrabble rack: ");
	    	
		    try {
		    	input = scan.next();
			}
		    catch (InputMismatchException e) {
		    	System.out.print("Invalid input. Please reenter: ");
		    	scan.nextLine();
		    	scan.close();
		    }
		    
		    bestVal = 0;
		    
		    // Iterate through mappedWordList
		    for(int i = 0; i < mappedWordList.size(); i++) {
		    	Map<Character, Integer> rackMap = mapSortedWord(input);
		    	Map<Character, Integer> validMap = mappedWordList.get(i);
		    	int wordVal = mappedWordValue(validMap);
		    	
		    	if(wordIsSubset(validMap, rackMap) && wordVal > bestVal) {
		    		bestWord = wordList.get(i);
		    		bestVal = wordVal;
		    	}
		    }
		    
		    if(bestVal > 0) {
		    	System.out.println("Best word is " + bestWord + ":" + bestVal + "points");
		    }
		    else {
		    	System.out.println("Uh oh! You can't make a word. Please choose a letter");
		    }
		    
	    }		
    }
	
	// MARK: - Functions
	static void processWords() {
		try {
			// Open file of valid words
            FileReader reader = new FileReader("bin/ValidWords");
            BufferedReader bufferedReader = new BufferedReader(reader);
 
            String line;
            
            // read each line
            while ((line = bufferedReader.readLine()) != null) {
            	// sort the strings
            	String sorted = sortedString(line);
            	
            	// map the word to find the count of each letter in the word
            	Map<Character, Integer> mapped = mapSortedWord(sorted);
                
            	mappedWordList.add(mapped);
            	wordList.add(line);
            }
            reader.close();
            
 
        } catch (IOException e) {
            e.printStackTrace();
        }
	}
	
	// MARK: - Utilities
		static String sortedString(String str) {

	        char[] chars = str.toCharArray();
	        Arrays.sort(chars);
	        return new String(chars);
		}
		
		static Map<Character, Integer> mapSortedWord(String word) {
			Map<Character, Integer> mappedWord = new HashMap<Character, Integer>();
			
			//initialize variables
			int charCount = 1;
			char current = word.charAt(0);
			
			//iterate through each character to get the character count
			for( int i = 1; i < word.length( ); i++ )
			{
			    char next = word.charAt( i );
			    if(current  == next) {
			    	charCount++;
			    }
			    else {
			    	mappedWord.put(current, charCount);
			    	charCount = 1;
			    	current = next;
			    }
			    
			}
			//add the last values
			mappedWord.put(current, charCount);
			
			//add actual word
			mappedWord.put(current, charCount);

			return mappedWord;
		}
		
		static boolean wordIsSubset(Map<Character, Integer> small, Map<Character, Integer> large) {

			//return false if small is not a subset of large
			for (Map.Entry<Character, Integer> entry : small.entrySet())
			{
			    if(large.get(entry.getKey()) == null || entry.getValue() > large.get(entry.getKey())) {
			    	return false;
			    }
			}

			return true;
		}
		
		static int mappedWordValue(Map<Character, Integer> word) {
			int total = 0;
			for (Map.Entry<Character, Integer> entry : word.entrySet())
			{   
			    total += letterVal(entry.getKey()) * entry.getValue();
			}
			return total;
		}
		
		static int letterVal(char letter) {
			int val = -1;
			switch(letter) {
			case 'a':
			case 'e':
			case 'i':
			case 'o':
			case 'u':
			case 'l':
			case 'n':
			case 's':
			case 't':
			case 'r':
				val = 1;
				break;
			case 'd':
			case 'g':
				val = 2;
				break;
			case 'b':
			case 'c':
			case 'm':
			case 'p':
				val = 3;
				break;
			case 'f':
			case 'h':
			case 'v':
			case 'w':
			case 'y':
				val = 4;
				break;
			case 'k':
				val = 5;
				break;
			case 'j':
			case 'x':
				val = 8;
				break;
			case 'q':
			case 'z':
				val = 10;
				break;
				
			default:
				val = -1;
				break;
			}
			return val;
		}
}

