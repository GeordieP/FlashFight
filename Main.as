package  {
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.display.SimpleButton;
	import fl.transitions.Tween;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.*;
	import flash.geom.ColorTransform;
	import fl.motion.Color;


	public class Main extends MovieClip{		// class

		// movieclips
		var player:MovieClip;
		var enemy:MovieClip;
		var playerHealthBar:MovieClip;
		var enemyHealthBar:MovieClip;

		// button
		var attackButton:SimpleButton;

		// timer
		var t:Timer;

		// numeric variables
		var vx:int = 20;		// movement (walking) speed

		var playerHealth:int = 100;		// starting health - adjust for 'handicap'
		var enemyHealth:int = 100;

		var p_damage:int;		// initial damage dealt
		var e_damage:int;

		var tempPosX:int, tempPosY:int;		// used for swapping out movieclips - holds the character's location while removing mc

		// other
		var p_canAttack:Boolean = true;
		var p_isAttacking:Boolean = false;

		var e_canAttack:Boolean = true;
		var e_isAttacking:Boolean = false;

		var attacker:String = "none";		// determines who's currently attacking (used for update logic)
		
		// tween stuff
		var p_oldHealth:Number = playerHealth;
		var e_oldHealth:Number = enemyHealth;
		var healthTween:Tween;


		public function Main(){		// constructor
			// Characters
			player = new Char_Idle();
			enemy = new Char_Idle();
			
			// Button
			attackButton = this.BTN_atk;

			// Health Bars
			enemyHealthBar = this.e_healthbar;
			playerHealthBar = this.p_healthbar;
			playerHealthBar.scaleX = -1;
			playerHealthBar.x = 590;

			this.addChild(player);
			player.x = 390; player.y = 407;
			this.addChild(enemy);
			enemy.x = 846; enemy.y = 407;
			enemy.scaleX = -1;

			// initially set the widths of the healthbars - do this so characters can start at lower amounts of health
			playerHealthBar.scaleX = -playerHealth * 0.01;
			enemyHealthBar.scaleX = enemyHealth * 0.01;

			player.transform.colorTransform = new ColorTransform(0, 1, 0);
			enemy.transform.colorTransform = new ColorTransform(1, 0, 0);

			attackButton.addEventListener(MouseEvent.MOUSE_DOWN, buttonClick, false, 0, true);

			t = new Timer(50);	// initialize the timer, but don't use it yet
		}

		public function buttonClick(evt:MouseEvent){
			if (p_canAttack){

				// Player attack
				attacker = "player";
				attackButton.transform.colorTransform = new ColorTransform(1, 0, 0, 1);		// make attack button red to show it can't be used
				p_isAttacking = true;

				// start the timer so player can be moved into position
				t.start();
				t.addEventListener(TimerEvent.TIMER, tick, false, 0, true);
			}
		}


		// Enemy Attack
		public function enemyAttack():void{
			if (e_canAttack){		// if enemy can attack
				attacker = "enemy";
				e_isAttacking = true;

				t.start();
				t.addEventListener(TimerEvent.TIMER, tick, false, 0, true);
			}
		}


		// The following two functions happen when the attack animation completes, but before the character is back in its original position
		public function playerAttackComplete(evt:Event):void{
			p_isAttacking = false;
			evt.target.removeEventListener("attack_complete", playerAttackComplete)
		}

		public function enemyAttackComplete(evt:Event):void{
			e_isAttacking = false;
			evt.target.removeEventListener("attack_complete", enemyAttackComplete)
		}

		// Turn is completed when character is back in its original position
		public function playerTurnComplete():void{

			// reset player's MC to idle animation
			tempPosX = player.x; tempPosY = player.y;
			this.removeChild(player);
			player = new Char_Idle();
			player.x = tempPosX; player.y = tempPosY;
			this.addChild(player);

			// re-apply color transform (green)
			player.transform.colorTransform = new ColorTransform(0, 1, 0);
			player.scaleX = 1;		// flip player back around so it's facing the correct way

			// Stop the timer and remove listener
			t.stop();
			t.removeEventListener(TimerEvent.TIMER, tick);

			this.damage_text.text = "";
			checkWin();

			if (enemyHealth > 0){
				e_canAttack = true;
				enemyAttack();
			}
		}

		public function enemyTurnComplete():void{
			// swap back to idle animation
			tempPosX = enemy.x; tempPosY = enemy.y;
			this.removeChild(enemy);
			enemy = new Char_Idle();
			enemy.x = tempPosX; enemy.y = tempPosY;
			this.addChild(enemy);
			enemy.transform.colorTransform = new ColorTransform(1, 0, 0);
			enemy.scaleX = -1;

			attackButton.transform.colorTransform = new ColorTransform(1, 1, 1, 1);		// reset attack button color to show it can be used again

			// stop timer
			t.stop();
			t.removeEventListener(TimerEvent.TIMER, tick);

			this.damage_text.text = "";
			checkWin();

			if (playerHealth > 0){
				p_canAttack = true;
			}
		}

		public function checkWin():void{
			// win conditions

			if (enemyHealth <= 0 || playerHealth <= 0){
				e_isAttacking = false;
				e_canAttack = false;

				p_isAttacking = false;
				p_canAttack = false;
			}

			if (enemyHealth <= 0){
				this.win_text.text = "PLAYER WINS!";

				tempPosX = enemy.x; tempPosY = enemy.y;
				this.removeChild(enemy);
				enemy = new Char_Dead();
				this.addChild(enemy);
				enemy.x = tempPosX; enemy.y = tempPosY;
				enemy.scaleX = -1;
				enemy.transform.colorTransform = new ColorTransform(0.4, 0.4, 0.4);
				player.transform.colorTransform = new ColorTransform(0, 0.6, 1);
			} else if (playerHealth <= 0){
				this.win_text.text = "COMPUTER WINS!";

				tempPosX = player.x; tempPosY = player.y;
				this.removeChild(player);
				player = new Char_Dead();
				this.addChild(player);
				player.x = tempPosX; player.y = tempPosY;
				enemy.transform.colorTransform = new ColorTransform(0, 0.6, 1);
				player.transform.colorTransform = new ColorTransform(0.4, 0.4, 0.4);
			}
		}

		public function decreaseHealth(defender:String):void{
			if (defender == "player"){
				if (playerHealth - e_damage > 0){		// prevents health from going lower than 0
					playerHealth -= e_damage;
				} else {
					playerHealth = 0;
				}

				healthTween = new Tween(playerHealthBar, "scaleX", Bounce.easeOut, -(p_oldHealth * 0.01), -(playerHealth * 0.01), 0.5, true);
				p_oldHealth = playerHealth;
				this.damage_text.text = e_damage + "!";
			} else if (defender == "enemy"){
				if (enemyHealth - p_damage > 0){
					enemyHealth -= p_damage;
				} else {
					enemyHealth = 0;
				}

				healthTween = new Tween(enemyHealthBar, "scaleX", Bounce.easeOut, (e_oldHealth * 0.01), (enemyHealth * 0.01), 0.5, true);
				e_oldHealth = enemyHealth;
				this.damage_text.text = p_damage + "!";
			}
		}


		public function attack():void{
			if (attacker == "player"){
				p_canAttack = false;		// set to false so this else only fires once
				
				p_damage = Math.random() * 90;	// choose damage

				// display attacking movieclip
				tempPosX = player.x; tempPosY = player.y;
				this.removeChild(player);
				player = new Char_Attack();
				player.x = tempPosX; player.y = tempPosY;
				this.addChild(player);

				// re-apply color transform
				player.transform.colorTransform = new ColorTransform(0, 1, 0);

				// add event listener for attack complete
				player.addEventListener("attack_complete", playerAttackComplete, false, 0, true);

				// decrease health of the enemy
				decreaseHealth("enemy");
			} else if (attacker == "enemy"){
				e_canAttack = false;

				e_damage = Math.random() * 90;

				// trace("enemy attacking");
				tempPosX = enemy.x; tempPosY = enemy.y;
				this.removeChild(enemy);
				enemy = new Char_Attack();
				enemy.x = tempPosX; enemy.y = tempPosY;
				this.addChild(enemy);
				enemy.transform.colorTransform = new ColorTransform(1, 0, 0);
				// trace("addchild enemy: enemy attack");
				enemy.scaleX = -1;
				enemy.addEventListener("attack_complete", enemyAttackComplete, false, 0, true);
				decreaseHealth("player");
			}
		}

		public function tick(evt:TimerEvent):void{
			// PLAYER ATTACK
			if (attacker == "player"){
				if (p_isAttacking){
					if ((player.x + player.width) < enemy.x - enemy.width/2){
						player.x += vx;
					} else if (p_canAttack) {		// once player gets to 'attacking location'
						attack();
					}
				} else if (!p_isAttacking && !e_isAttacking){		// after the attack animation has completed -- at this point the 'attack' is still not over, character has to walk back
					if (player.x > 390){
						if (player.scaleX != -1){
							player.scaleX = -1;
						}
						player.x -= vx;
					} else if (player.x == 390){		// once character reaches their original point, their turn is complete
						playerTurnComplete();
					}
				}
			} 

			// ENEMY ATTACK
			else if (attacker == "enemy"){
				if (e_isAttacking){
					if (enemy.x > (player.x + player.width) + player.width/2){
						enemy.x -= vx;
					} else if (e_canAttack) {
						attack();
					}
				} else if (!e_isAttacking && !e_isAttacking){
					if (enemy.x < 846){
						if (enemy.scaleX != 1){
							enemy.scaleX = 1;
						}
						enemy.x += vx;
					} else if (enemy.x == 846){
						enemyTurnComplete();
					}
				}
			}
		}
	}
}