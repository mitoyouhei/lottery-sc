// 引入 Chai 库，用于断言
const {expect} = require('chai')
const {address} = require('hardhat/internal/core/config/config-validation')

// 定义 Casino 合约测试套件
describe('Casino', function () {
    // 声明全局变量
    let diceGame
    let player1
    let player2
    let player1Bet
    let player2Bet

    describe('DICE', () => {
        const gameId = 1
        // 在每个测试用例之前部署新的 DiceGame 合约
        beforeEach(async function () {
            const Casino = await ethers.getContractFactory('Casino')
            casino = await Casino.deploy()
            await casino.deployed()

            // 创建两个测试用的玩家地址
            ;[player1, player2] = await ethers.getSigners()
            player1Bet = 1
            player2Bet = 6
        })

        it('should allow players to create and play the game', async function () {
            // 玩家 1 加入游戏
            await casino.createGame(gameId, player1Bet, {
                value: ethers.utils.parseEther('100'),
            })
            const currentGames = await casino.getGames()
            const diceGame = currentGames[0]
            const gamblerA = diceGame.gamblers[0]

            expect(gamblerA.id).to.equal(player1.address)
            expect(gamblerA.bet).to.equal(player1Bet)

            // 玩家 2 加入游戏
            await casino.connect(player2).playGame(diceGame.id, player2Bet, {
                value: ethers.utils.parseEther('100'),
            })
            const gameAfterPlay = (await casino.getGames())[0]
            const gamblerB = gameAfterPlay.gamblers[1]

            expect(gamblerB.id).to.equal(player2.address)
            expect(gamblerB.bet).to.equal(player2Bet)
        })

        it('should show error when betAmount are different', async function () {
            const player1BetAmount = '100'
            const player2BetAmount = '50'
            // 玩家 1 加入游戏
            await casino.createGame(gameId, player1Bet, {
                value: ethers.utils.parseEther(player1BetAmount),
            })
            const currentGames = await casino.getGames()
            const diceGame = currentGames[0]
            // 玩家 2 加入游戏
            try {
                const result = await casino
                    .connect(player2)
                    .playGame(diceGame.id, player2Bet, {
                        value: ethers.utils.parseEther(player2BetAmount),
                    })
                expect(result).to.be.null
            } catch (err) {
                expect(err).to.not.be.null
            }
        })
    })

    describe('ROC_PAPER_SCISSORS', () => {
        const gameId = 2
        // 在每个测试用例之前部署新的 DiceGame 合约
        beforeEach(async function () {
            const Casino = await ethers.getContractFactory('Casino')
            casino = await Casino.deploy()
            await casino.deployed()

            // 创建两个测试用的玩家地址
            ;[player1, player2] = await ethers.getSigners()
            player1Bet = 1 // ROCK
            player2Bet = 2 // PAPER
        })

        // 测试 createGame 函数
        it('should create a game and transfer wager when call createGame', async function () {
            await casino.createGame(gameId, player1Bet, {
                value: ethers.utils.parseEther('100'),
            })

            const currentGames = await casino.getGames()
            const rockPaperScissors = currentGames[0]
            const gamblerA = rockPaperScissors.gamblers[0]

            expect(gamblerA.id).to.equal(player1.address)
            expect(gamblerA.bet).to.equal(0)
            expect(currentGames.length).to.equal(1)
        })

        // 测试 playGame 函数，(TODO 并且 player2 是 winner)
        it('should play game and transfer wager when call playGame', async function () {
            await casino.createGame(gameId, player1Bet, {
                value: ethers.utils.parseEther('100'),
            })
            const rockPaperScissors = (await casino.getGames())[0]

            try {
                const result = await casino
                    .connect(player2)
                    .playGame(rockPaperScissors.id, player2Bet, {
                        value: ethers.utils.parseEther('100'),
                    })
                expect(result).to.be.null
            } catch (e) {}
            const gamesAfterPlay = await casino.getGames()
            const playedRockPaperScissors = gamesAfterPlay[0]
            const gamblerB = playedRockPaperScissors.gamblers[1]

            expect(gamblerB.id).to.equal(player2.address)
            expect(gamblerB.bet).to.equal(player2Bet)
        })
    })
})
