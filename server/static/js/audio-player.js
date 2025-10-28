(function () {
	'use strict';

	// Does the browser actually support the audio element?
	var supportsaudio = !!document.createElement('audio').canPlayType;

	if (supportsaudio) {
		// disable the controls
		var enabled = false;

		// Obtain handles to main elements
		var audioContainer = document.getElementById('audioContainer');
		var audio = document.getElementById('audio');
		var audioControls = document.getElementById('audio-controls');

		// Hide the default controls
		audio.controls = false;

		// Display the user defined audio controls
		audioControls.setAttribute('data-state', 'hidden');

		var enablePlayer = function() {
			enabled = true;
			audioControls.setAttribute('data-state', 'visible');
		}

		// Obtain handles to buttons and other elements
		var playpause = document.getElementById('playpause');
		var stop = document.getElementById('stop');
		var progress = document.getElementById('progress');
		var progressBar = document.getElementById('progress-bar');

		// If the browser doesn't support the progress element, set its state for some different styling
		var supportsProgress = (document.createElement('progress').max !== undefined);
		if (!supportsProgress) {
			console.log("Does not support <progress>");
			progress.setAttribute('data-state', 'fake');
		} 

		// Only add the events if addEventListener is supported (IE8 and less don't support it, but that will use Flash anyway)
		if (document.addEventListener) {
			// Wait for the audio's meta data to be loaded, then set the progress bar's max value to the duration of the audio
			audio.addEventListener('loadedmetadata', function() {
				progress.setAttribute('max', audio.duration);
			});
			// do the same, for the whole file to be loaded, and enable the player
			audio.addEventListener('canplaythrough', function() {
				enablePlayer();
			});

			// Changes the button state of certain button's so the correct visuals can be displayed with CSS
			var changeButtonState = function(type) {
				// Play/Pause button
				if (type == 'playpause') {
					if (audio.paused || audio.ended) {
						playpause.setAttribute('data-state', 'play');
					}
					else {
						playpause.setAttribute('data-state', 'pause');
					}
				}
			}

			// Add event listeners for audio specific events
			audio.addEventListener('play', function() {
				changeButtonState('playpause');
			}, false);
			audio.addEventListener('pause', function() {
				changeButtonState('playpause');
			}, false);

			// Add events for all buttons			
			playpause.addEventListener('click', function(e) {
				if (audio.paused || audio.ended) audio.play();
				else audio.pause();
			});			

			// The Media API has no 'stop()' function, so pause the audio and reset its time and the progress bar
			stop.addEventListener('click', function(e) {
				audio.pause();
				audio.currentTime = 0;
				progress.value = 0;
				// Update the play/pause button's 'data-state' which allows the correct button image to be set via CSS
				changeButtonState('playpause');
			});

			// As the audio is playing, update the progress bar
			audio.addEventListener('timeupdate', function() {
				// For mobile browsers, ensure that the progress element's max attribute is set
				if (!progress.getAttribute('max')) progress.setAttribute('max', audio.duration);
				progress.value = audio.currentTime;
				progressBar.style.width = Math.floor((audio.currentTime / audio.duration) * 100) + '%';
			});

			// React to the user clicking within the progress bar
			progress.addEventListener('click', function(e) {
				//var pos = (e.pageX  - this.offsetLeft) / this.offsetWidth; // Also need to take the parent into account here as .controls now has position:relative
				var pos = (e.pageX  - (this.offsetLeft + this.offsetParent.offsetLeft)) / this.offsetWidth;
				audio.currentTime = pos * audio.duration;
			});


		}
	 }

 })();