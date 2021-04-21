const path = require('path')
const fs = require('fs')

module.exports = {
    transforms: {
      /* Match <!-- AUTO-GENERATED-CONTENT:START (SNIPPET:src=./relative/path/to/code.swift) --> */
      SNIPPET(content, options, config) {
        let code
        let syntax = options.syntax
        if (!options.src) {
          return false
        }
        const fileDir = path.dirname(config.originalPath)
          const filePath = path.join(fileDir, options.src)
          try {
            code = fs.readFileSync(filePath, 'utf8', (err, contents) => {
              if (err) {
                console.log(`FILE NOT FOUND ${filePath}`)
                console.log(err)
                 // throw err
              }
              return contents
            })
          } catch (e) {
            console.log(`FILE NOT FOUND ${filePath}`)
            throw e
          }
          if (!syntax) {
            syntax = path.extname(filePath).replace(/^./, '')
          }
      
        // Parse inside function

        // Get index of `func` keyword
        var funcStart = code.indexOf('func')
        // Get temporary string up to index of `func` keyword
        var tempString = code.substring(0, funcStart)
        // Get number of lines for tempString - this is the line of `func` keyword
        funcStart = tempString.split('\n').length
        // Get lines from original code
        var codeLines = code.split('\n')
        // Get inside func, -2 is for discarding trailing newline and closing bracket of function
        code = codeLines.slice(funcStart, codeLines.length - 2).join('\n')

        console.log('replacing')

        // trim leading four spaces (tabs) from each line - this is necessary since the whole thing was indented
        code = code.replace(/^[^\r\n]   /gm, "")
      
        let header = ''
        if (options.header) {
          header = `\n${options.header}`
        }
      
        return `
<!-- The below code snippet is automatically added from ${options.src} -->
\`\`\`${syntax}${header}
${code}
\`\`\`
        `
      }
    },
    callback: function () {
      console.log('done')
    }
  }