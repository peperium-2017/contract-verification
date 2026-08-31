const path = require('path')
const fs = require('fs')
const solc = require('solc')         // 0.4.10 - series 1 & gallery v1
const solc0416 = require('solc0416') // 0.4.16 - series 2 & gallery v2

function readSource(filename) {
    return fs.readFileSync(path.resolve(__dirname, 'contracts', filename), 'UTF-8')
}

function readTargetBytecode(filename) {
    return fs.readFileSync(path.resolve(__dirname, 'bytecode', filename), 'UTF-8').trim().replace(/^0x/, '')
}

// Strip every embedded solc metadata block (32-byte swarm hash + trailing "0029").
// A contract that deploys another contract (e.g. a factory calling `new Child(...)`)
// embeds the child's full creation bytecode -- including the child's own metadata --
// inline, so a single bytecode string can contain more than one occurrence.
function stripMetadata(bytecode) {
    return bytecode.replace(/a165627a7a72305820[0-9a-f]{64}0029/g, '')
}

function verify(label, { compiler, sourceFile, contractName, targetBytecodeFile, optimize }) {
    const src = readSource(sourceFile)
    const output = compiler.compile(src, optimize)

    const compiled = output.contracts && output.contracts[`:${contractName}`]
    if (!compiled) {
        console.log(`[${label}] Compilation failed or contract ${contractName} not found`)
        if (output.errors) console.log(output.errors)
        return
    }

    const bc = stripMetadata(compiled.runtimeBytecode)
    const target = stripMetadata(readTargetBytecode(targetBytecodeFile))

    if (bc === target) {
        console.log(`[${label}] EUREKA!!!!! Found a matching bytecode`)
    } else {
        console.log(`[${label}] Matching bytecode not found`)
    }
}

verify('series-1', {
    compiler: solc,
    sourceFile: 'series-1.sol',
    contractName: 'CardToken',
    targetBytecodeFile: 'series-1.txt', // KFPEPE, 0x648445e48093d999966375b30186D433fEF9c364
    optimize: 1, // Etherscan: optimization ON, runs=1
})

verify('series-2', {
    compiler: solc0416,
    sourceFile: 'series-2.sol',
    contractName: 'CardToken2',
    targetBytecodeFile: 'series-2.txt', // PEPESTENCIL, 0x5921F43985a027ba74EE110b77DcE09B96De943E
    optimize: 0, // Etherscan: optimization OFF
})

verify('gallery-v1', {
    compiler: solc,
    sourceFile: 'gallery-v1.sol',
    contractName: 'CardTokenFactory',
    targetBytecodeFile: 'gallery-v1.txt', // 0xD875c876435A79b5EB2099D06Aa97FFd4fB6FC9d
    optimize: 1, // Etherscan: optimization ON, runs=200
})

verify('gallery-v2', {
    compiler: solc0416,
    sourceFile: 'gallery-v2.sol',
    contractName: 'CardTokenFactory2',
    targetBytecodeFile: 'gallery-v2.txt', // 0xB4e34890034a13325363b3226DCE8EeEc292D626
    optimize: 0, // Etherscan: optimization OFF
})
