/*
 * Columnar Transposition decryption tool in Swift by Andrew Lubinger
 *
 * Not necessarily the most efficient, but it's not brute force because that's... like... impossible.
 * Uses an algorithm with actual scoring.
 *
 * Enter your ciphertext.
 * Enter the key length to try.
 * It'll use English frequency analysis for tetragrams to hopefully find the correct plaintext.
 *
 * In Windows, after Swift is installed correctly, compile and run with the following commands in an admin x64 VS 2019 Command Prompt
 * set SWIFTFLAGS=-sdk %SDKROOT% -resource-dir %SDKROOT%/usr/lib/swift -I %SDKROOT%/usr/lib/swift -L %SDKROOT%/usr/lib/swift/windows
 * swiftc %SWIFTFLAGS% -emit-executable -o Columnar.exe main.swift tetragrams.swift
 * Columnar.exe
 */

import Foundation

//First entry point.

//User inputs
//Ciphertext, spaces can be included
print("Enter the ciphertext:\n")
let ciphertext = readLine()!.replacingOccurrences(of: " ", with: "").lowercased()
//The key length. Can be determined using other tools to find factors and then vowel counts.
print("Enter the key length:\n")
let keyLength = Int(readLine()!)!
//Ask how many tries until just returning the best result. Too large and it might not ever print the best result, too few and it might be close but not quite make it.
//I've seen it take between about 3k-15k guesses when it works in a reasonable amount of time. I'd say 20k is probably a reasonable maximum then to not waste time.
print("What is the maximum number of guesses I can make? I recommend 20000.\n")
let maximumTries = Int(readLine()!)!

//Create a grid using the ciphertext and key length.
//Place into grid top->bottom, left->right.
//Read as plaintext left->right, top->bottom.
var colSize = ciphertext.count / keyLength
var grid = [[Character]]()
for i in 0..<keyLength {
  //Add a row which is an array of characters from the substring of current position to current position + colSize.
  let row = (Array(String(ciphertext[ciphertext.index(ciphertext.startIndex, offsetBy: i*colSize)...ciphertext.index(ciphertext.startIndex, offsetBy: (i+1)*colSize-1)])))
  grid.append(row)
}

//Decipher using the key
//Takes the key as a paramter
//Returns the plaintext
func decipher(key: [Int]) -> String {
  //Use the key to decipher
  var answer = ""

  //First we need to get the columns in the right order.
  var newGrid = [[Character]]()
  for index in key {
    newGrid.append(grid[index])
  }

  //Now we need to read right->left.
  for j in 0..<colSize {
    for i in 0..<keyLength {
      answer += String(newGrid[i][j])
    }
  }

  return answer
}

var shouldTryAgain = false
var usedKeys = Set<[Int]>()
var on1 = -1
var on2 = -1
var ooption = -1

//Backtrack one step to get the last grid.
//This is useful when we can't find a new grid from the current one, so we try the last known grid.
//Takes grid as parameter and uses o-variables to backtrack and return the old grid.
// func backtrack(grid: [[String]]) -> [[String]] {
//   //Do the change again. For each case, reverse is the same code as forward since they're all swaps or flips.
//   var oldGrid = grid
//   switch ooption {
//     case 0:
//       //swap rows
//       let row = oldGrid[on1]
//       oldGrid[on1] = oldGrid[on2]
//       oldGrid[on2] = row

//     case 1:
//       //swap columns
//       for i in 0...4 {
//         let char = oldGrid[i][on1]
//         oldGrid[i][on1] = oldGrid[i][on2]
//         oldGrid[i][on2] = char
//       }

//     case 2:
//       //horizontal flip
//       for i in 0...4 {
//         var char = oldGrid[i][0]
//         oldGrid[i][0] = oldGrid[i][4]
//         oldGrid[i][4] = char
//         char = oldGrid[i][1]
//         oldGrid[i][1] = oldGrid[i][3]
//         oldGrid[i][3] = char
//       }

//     case 3:
//       //vertical flip
//       for i in 0...4 {
//         var char = oldGrid[0][i]
//         oldGrid[0][i] = oldGrid[4][i]
//         oldGrid[4][i] = char
//         char = oldGrid[1][i]
//         oldGrid[1][i] = oldGrid[3][i]
//         oldGrid[3][i] = char
//       }

//     default:
//       //character swap
//       let char = oldGrid[on1][on2]
//       oldGrid[on1][on2] = oldGrid[on3][on4]
//       oldGrid[on3][on4] = char
//   }
//   ooption = -1 //reset it so we don't try again with the same steps
//   return oldGrid
// }

//Useful extension to rotate an array.
extension RangeReplaceableCollection {
  mutating func rotateRight(positions: Int) {
    let index = self.index(endIndex, offsetBy: -positions, limitedBy: startIndex) ?? startIndex
    let slice = self[index...]
    removeSubrange(index...)
    insert(contentsOf: slice, at: startIndex)
  }
}

//Get a new key.
//Make sure it's not in the usedKeys set.
func keyFrom(key: [Int]) -> [Int] {
  //Either make a column swap, or rotate the table a number of positions.
  var newKey = key
  var attempts = 0
  var n1 = -1
  var n2 = -1
  var option = -1
  //Try to get a new key but need to stop trying after a certain number of attempts
  while(usedKeys.contains(newKey) && attempts < 100000) {
    attempts += 1
    newKey = key

    //Choose a random option
    //We should definitely do more column swaps than rotations though.
    option = Int.random(in: 0...100)
    switch option {
      case 1:
        //Rotate table.
        newKey.rotateRight(positions: Int.random(in: 1..<keyLength))

      default:
        //Swap columns
        n1 = Int.random(in: 0..<keyLength)
        n2 = Int.random(in: 0..<keyLength)
        let i = newKey[n1]
        newKey[n1] = newKey[n2]
        newKey[n2] = i
    }
  }
  // if(attempts == 100000) {
  //   if(ooption != -1) {
  //     //Go back one step and try again
  //     newGrid = gridFrom(grid: backtrack(grid: newGrid))
  //   } else {
  //     //Start over with a new random key starting point
  //     shouldTryAgain = true
  //   }
  // } else {
  //   //Found a new grid, keep track of this change so we can go back if necessary
  //   on1 = n1
  //   on2 = n2
  //   on3 = n3
  //   on4 = n4
  //   ooption = option
  //   usedGrids.insert(newGrid)
  // }
  if(attempts == 100000) {
    shouldTryAgain = true
    print("ERROR: Can't find an unused key variation.")
  } else {
    usedKeys.insert(newKey)
  }
  return newKey
}

//Calculate the score of the plaintext.
//Specifically, find the tetragrams in the plaintext and add their english frequency value to the score.
//score = sum(quartet.each { $0.englishFreq })
//Higher score is better
func getScore(text: String) -> Double {
  var score = 0.0
  for pairPos in 0..<text.count - 3 {
    let quartet = String(text[text.index(text.startIndex, offsetBy: pairPos)...text.index(text.startIndex, offsetBy: pairPos + 3)])
    if let englishFrequency = tetragrams[quartet] {
      score += englishFrequency
    }
  }
  return score
}

//Some variables
var tries = 0
var key = ([Int](0..<keyLength)).shuffled() //The key is the ordering of columns
var topKey = key
var topNewKey = key
var topScore = -1.0
var topNewScore = -1.0
var topPlaintext = ""

//Main program entry point.

//Run columnar transposition over and over with different keys keeping track of the best 
//option of plaintext/key. At that point, show the user the possible plaintext and key.
//Also show each time the new top score is found
while(tries < maximumTries) {
  if(shouldTryAgain) {
    shouldTryAgain = false
    topNewScore = -1.0
    key = ([Int](0..<keyLength)).shuffled()
  } else {
    key = keyFrom(key: topNewKey)
  }
  let plaintext = decipher(key: key)
  let score = getScore(text: plaintext)
  //Higher score is better
  if(score >= topNewScore) {
    topNewScore = score
    topNewKey = key
    print("\n\n")
    print(plaintext)
    print(score)
    print(key)
    print("\n\n")
    if(score >= topScore) {
      topScore = score
      topKey = key
      topPlaintext = plaintext
    }
  }
  tries += 1
}
print("\n\nTop score was:")
print(topScore)
print("with key:")
print(topKey)
print("resulting in:")
print(topPlaintext)
