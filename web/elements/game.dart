import 'dart:html';
import 'package:polymer/polymer.dart';

const DEFAULT_NUM_PLAYERS = 4;
const DEFAULT_NUM_ROUNDS = 30;

class Player extends Observable {
  Game game;
  int _total = 0;
  @observable String name;
  @observable ObservableList<Score> scores;
  @reflectable get total => _total;
  
  Player(this.game, this.name) {
    this.scores = new ObservableList<Score>();
    for(var round in game.rounds) {
      scores.add(new Score(this, ''));
    }
    onPropertyChange(this, #scores, () {
      _total = notifyPropertyChange(#total, _total, calculateTotal());
    });
  }

  int calculateTotal() {
    return scores.fold(0, (total, score) => total + (score.score == '' ? 0 : int.parse(score.score, radix: 10, onError: (_) => 0)));
  }
  
  void roundAdded() {
    scores.add(new Score(this, ''));
  }

}

class Score extends Observable {
  Player player;
  @observable String score;
  
  Score(this.player, this.score) {
    onPropertyChange(this, #score, () {
      player.notifyPropertyChange(#scores, 1, 2);
    });
  }
}

class Round extends Observable {
  Game game;
  @observable int roundNumber;
  
  Round(this.game, this.roundNumber);
}

@CustomTag('sk-game')
class Game extends PolymerElement {
  
  bool _addingRound = false;
  String nextCell = '';
  
  @observable ObservableList<Player> players;
  @observable ObservableList<Round> rounds;
  MutationObserver roundObserver;

  Game.created() : super.created() {
    roundObserver = new MutationObserver(_onMutation);
    roundObserver.observe(shadowRoot.querySelector('.score-wrapper'), childList: true);
  }
  
  void ready() {
    async((_) {
      setup();  
    });
  }
  
  void addPlayer() {
    players.add(new Player(this, '[Enter Name]'));
  }
  
  void removePlayer(Event e, var detail, Element target) {
    if(window.confirm("Are you sure you want to remove this player?")) {
      var idx = int.parse(target.attributes['data-player-index']);
      players.removeAt(idx);
    }
  }
  
  void addRound() {
    rounds.add(new Round(this, rounds.length));
    for(var player in players) {
      player.roundAdded();
    }
  }
  
  void reset() {
    if(window.confirm("This will reset all players and scores. Are you sure you want to continue?")) {
      rounds = null;
      players = null;
      setup();
    }
  }
  
  // Initialize board with 30 rounds and 4 players...
  void setup() {
    if (rounds == null) rounds = new ObservableList<Round>();
    for(var i = 0; i < DEFAULT_NUM_ROUNDS; i++) {
      rounds.add(new Round(this, i));
    }
    
    if (players == null) players = new ObservableList<Player>();
    for(var i = 1; i <= DEFAULT_NUM_PLAYERS; i++) {
      players.add(new Player(this, 'Player $i'));
    }
  }
    
  void keyupAction(Event e, var detail, Element target) {
    var playerId = int.parse(target.attributes['data-player-index']),
        roundNumber = int.parse(target.attributes['data-round-number']);
 
    switch(e.keyCode) {
      case KeyCode.ENTER:
      case KeyCode.DOWN: {
        e.preventDefault();  
        nextCell = 'input.player-$playerId.round-${roundNumber+1}';
        if(roundNumber < rounds.length-1) {
          _focusNextCell();   
        }
        else {
          _addingRound = true;
          addRound();
        } 
        break;
      }
      case KeyCode.UP: {
        e.preventDefault();
        nextCell = 'input.player-$playerId.round-${roundNumber-1}';
        if(roundNumber > 0) {
          _focusNextCell();
        }
        break;
      }
    }
  }
  
  void _onMutation(List<MutationRecord> mutations, MutationObserver observer) {
    if(_addingRound) {
      _focusNextCell();
    }
  }
  
  void _focusNextCell() {
    InputElement next = shadowRoot.querySelector(nextCell);
    next.focus();
  }

}

