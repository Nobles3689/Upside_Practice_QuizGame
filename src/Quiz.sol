// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Quiz{
    struct Quiz_item {
      uint id;
      string question;
      string answer;
      uint min_bet;
      uint max_bet;
   }
    
    mapping(address => uint256)[] public bets;
    uint public vault_balance;
    Quiz_item[] private quiz_pool;//지금까지 추가된 퀴즈들!
    mapping(address => bool)[] private result;//정답 여부 저장
    address private admin;

    constructor () {
        admin = msg.sender;
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }

    function addQuiz(Quiz_item memory q) public {
        require(msg.sender == admin, "You have no authority.");
        quiz_pool.push(q);//퀴즈풀에 퀴즈 추가
        bets.push();//새 퀴즈에 대한 배팅
        result.push();//정답 확인을 위해 추가
    }

    function getQuiz(uint quizId) public view returns (Quiz_item memory) {
        require(quizId > 0 && quizId <= getQuizNum(), "There is no quiz for that id.");
        Quiz_item memory tmp_q;//임시 변수
        tmp_q = quiz_pool[quizId-1];
        tmp_q.answer = "";//정답 지우기
        return tmp_q;
    }

    function getQuizNum() public view returns (uint){
        return quiz_pool.length;//퀴즈풀의 길이 = 퀴즈의 개수
    }
    
    function betToPlay(uint quizId) public payable {
        require(quizId > 0 && quizId <= getQuizNum(), "There is no quiz for that id.");
        Quiz.Quiz_item memory tmp_q = quiz_pool[quizId-1];
        //배팅 범위 확인
        require(msg.value >= tmp_q.min_bet && msg.value <= tmp_q.max_bet, "Out of range of betting amount.");
        bets[quizId-1][msg.sender] += msg.value;//배팅!
    }

    function getAnswer(uint quizId) public view returns (string memory){
        require(quizId > 0 && quizId <= getQuizNum(), "There is no quiz for that id.");
        return quiz_pool[quizId-1].answer;//퀴즈의 답 반환
    }

    function solveQuiz(uint quizId, string memory ans) public returns (bool) {
        require(quizId > 0 && quizId <= getQuizNum(), "There is no quiz for that id.");
        if (keccak256(abi.encodePacked(ans)) == keccak256(abi.encodePacked(quiz_pool[quizId-1].answer))){
            result[quizId-1][msg.sender] = true;//정답 체크
            return true;
        }else{//틀리면 배팅 금액 몰수
            vault_balance += bets[quizId-1][msg.sender];
            bets[quizId-1][msg.sender] = 0;
            return false;
        }
    }

    function claim() public {
        uint reward = 0;
        for(uint i = 0; i<getQuizNum(); i++){//퀴즈풀 돌면서 정답 맞춘 퀴즈에 배팅한 금액 더하기
            if(result[i][msg.sender]){
                result[i][msg.sender] = false;
                reward += bets[i][msg.sender];
                bets[i][msg.sender] = 0;
            }
        }
        vault_balance -= reward;
        payable(msg.sender).call{value: reward*2}("");//testClaim에서 배팅금액의 2배인지 체크하기 때문
        
    }
    //setUp에서 5 이더 보내는 것 받기 위함 - 안하니까 언더플로우 뜨더라구요...
    receive() external payable {
        vault_balance += msg.value;
    }
}
