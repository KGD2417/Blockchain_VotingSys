const express = require("express");
const cors = require("cors");
const { Web3 } = require("web3");
const fs = require("fs");
const path = require("path");

const app = express();
app.use(cors());
app.use(express.json());

const web3 = new Web3("http://127.0.0.1:7545"); // Connect to Ganache

const contractJson = JSON.parse(fs.readFileSync(path.resolve(__dirname, "../blockchain/build/contracts/Voting.json"), "utf8"));
const contractAddress = contractJson.networks[5777].address;
const contract = new web3.eth.Contract(contractJson.abi, contractAddress);

// Helper function to convert BigInt to string
function convertBigIntToString(obj) {
    for (let key in obj) {
        if (typeof obj[key] === 'bigint') {
            obj[key] = obj[key].toString();
        } else if (typeof obj[key] === 'object') {
            convertBigIntToString(obj[key]); // Recursively handle nested objects
        }
    }
    return obj;
}

app.get("/candidates", async (req, res) => {
    try {
        const candidatesCount = await contract.methods.candidatesCount().call();
        let candidates = [];

        for (let i = 1; i <= candidatesCount; i++) {
            let candidate = await contract.methods.candidates(i).call();

            // Convert BigInt values to strings
            candidate = convertBigIntToString(candidate);
            candidates.push(candidate);
        }

        res.json(candidates);
    } catch (error) {
        res.status(500).send(error.toString());
    }
});

app.post("/vote", async (req, res) => {
    try {
        const { candidateId, voterAddress } = req.body;
        const result = await contract.methods.vote(candidateId).send({ from: voterAddress });

        // Convert BigInt values properly for JSON serialization
        const serializedResult = JSON.stringify(result, (_, value) =>
            typeof value === "bigint" ? value.toString() : value
        );
        
        res.json(JSON.parse(serializedResult)); // Ensure valid JSON response
    } catch (error) {
        res.status(500).send(error.toString());
    }
});


app.post("/addCandidate", async (req, res) => {
    try {
        const { name, adminAddress } = req.body;
        const result = await contract.methods.addCandidate(name).send({ from: adminAddress });

        // Convert BigInt values in the result to strings
        const serializedResult = convertBigIntToString(result);
        res.json(serializedResult);
    } catch (error) {
        res.status(500).send(error.toString());
    }
});

app.listen(3000, () => console.log("Server running on port 3000"));