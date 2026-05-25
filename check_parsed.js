const fs = require('fs');
const errors = fs.readFileSync('errors.txt', 'utf8').split('\n');
const filesToFix = {};
errors.forEach(line => {
  if (line.includes("Type 'Resource' is not assignable to type 'string'") || 
      line.includes("Argument of type 'Resource' is not assignable to parameter of type 'string'")) {
    const match = line.match(/At File:\s*(.*?):(\d+):\d+/);
    if (match) {
      let file = match[1];
      if (file.includes('F:/DevEcoStudioProject/NGF/')) {
        file = file.replace('F:/DevEcoStudioProject/NGF/', '');
      }
      const lineNum = parseInt(match[2], 10);
      if (!filesToFix[file]) {
        filesToFix[file] = new Set();
      }
      filesToFix[file].add(lineNum);
    }
  }
});
console.log(filesToFix);
