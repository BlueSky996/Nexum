"use client";

import { useState } from "react";
import { ethers } from "ethers";
import CreditVaultAbi from "../abis/CreditVault.json"; // ABI JSON


declare global {
    interface Window {
        ethereum: ethers.Eip1193Provider;
    }
}

export default function VaultApp() {
    const [account, setAccount] = useState<string | null>(null);
    const [info, setInfo] = useState({ collateral: "0", debt: "0", maxWithdraw: "0"});
    const vaultAddress = "0x13aaCcF54a96D9eD9848Aee73e4A5c15BF0d7127"; // deployed vault address

    const fetchInfo = async (acc: string) => { // Show info for the connected wallet
        if (!window.ethereum) return;
        const provider = new ethers.BrowserProvider(window.ethereum);
        const vault = new ethers.Contract(vaultAddress, CreditVaultAbi, provider);
        const collateral = await vault.collateral(acc);
        const debt = await vault.debt(acc);
        const maxWithdraw = collateral - debt;
        setInfo({
            collateral: ethers.formatEther(collateral),
            debt: ethers.formatEther(debt),
            maxWithdraw: ethers.formatEther(maxWithdraw < BigInt(0) ? BigInt(0) : maxWithdraw),
        });
    };

    // Connect Wallet
    const connectWallet = async () => {
        if (!window.ethereum) return alert("Install MetaMask!");
        const [selected] = await window.ethereum.request({ method: "eth_requestAccounts"}) as string
        setAccount(selected);
        fetchInfo(selected);
    };

    const getContract = (signer: ethers.Signer) => {
        return new ethers.Contract(vaultAddress, CreditVaultAbi, signer);
    };

    // Deposit Eth 
    const deposit = async (amount: string) => {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const vault = getContract(signer);
        const tx = await vault.deposit({ value: ethers.parseEther(amount) });
        await tx.wait();
        alert("Deposit Successfull");
    };


    const mint = async (amount: string) => {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const vault = getContract(signer);
        const tx = await vault.mint(ethers.parseEther(amount));
        await tx.wait();
        alert("Mint successful!");
    };


    const repay = async (amount: string) => {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const vault = getContract(signer);

        // approve first
        const creditAddress: string = await vault.credit();
        const creditAbi = ["function approve(address spender, uint256 amount) public returns (bool)"]
        const credit = new ethers.Contract(creditAddress, creditAbi, signer);
        await credit.approve(vaultAddress, ethers.parseEther(amount));

        const tx = await vault.repay(ethers.parseEther(amount));
        await tx.wait();
        alert("Repay successful");
    };

    // Withdraw ETH
    const withdraw = async (amount: string) => {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const vault = getContract(signer);
        const tx = await vault.withdraw(ethers.parseEther(amount));
        await tx.wait();
        alert("Withdraw successful");
    };


    const buttonStyle: React.CSSProperties = {
    padding: "10px 20px",
    borderRadius: "8px",
    border: "none",
    cursor: "pointer",
    fontWeight: "bold",
    background: "#6366f1",
    color: "#fff",
    margin: "4px",
};

    return (
        <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", flexDirection: "column", gap: "20px"}}>
            {!account ? (
                <button onClick={connectWallet} style={buttonStyle}>Connect Wallet</button>
            ) : (
                <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "20px"}}>
                    <p style={{ color: "#888", fontSize: "13px"}}>Connected: {account}</p>

                    {/* info */}
                    <div style={{ display: "flex", gap: "24px", marginBottom: "8px", fontSize: "13px"}}>
                        <span>Deposited: <b>{info.collateral} ETH </b></span>
                        <span>Debt: <b>{info.debt} BND </b></span>
                        <span>Withdrawable: <b>{info.maxWithdraw} ETH </b></span>
                    </div>



                    {/* buttons */}
                    <div style={{ display: "flex", gap: "24px"}}>
                    <button onClick={() => deposit("0.0005").then(() =>fetchInfo(account!))}  style={buttonStyle}>Deposit 0.0005 ETH</button>
                    <button onClick={() => mint("0.0001").then(() => fetchInfo(account!))}     style={buttonStyle}>Mint 0.0001 Bond</button>
                    <button onClick={() => repay("0.0001").then(() => fetchInfo(account!))}    style={buttonStyle}>Repay 0.0001 Bond</button>
                    <button onClick={() => withdraw("0.0001").then(() => fetchInfo(account!))} style={buttonStyle}>Withdraw 0.0001 ETH</button>
                </div>
            </div>
            )}

        </div>
    );
}