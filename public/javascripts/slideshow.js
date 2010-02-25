
// Get a random image from the server, but take care to not get
// an image that is already being displayed
function getRandomImage() {
	if (imagesAreLoaded())
		new Ajax.Request('random_slide?'+ currentImages(), {
			method: 'GET',
			onSuccess: function(response) {
				replaceImage(response.responseText);
		}
	})
}

function replaceImage(image_data) {
	// e is the elementized version of our html string received from the Ajax call
	// images is all the thumbnail elements
	// n is the index of the image we will replace
	var images = $$('._thumbnail'), n = Math.floor(Math.random()*images.length);
	
	// We want to update with the new image, but defer image loading until
	// we're ready to capture the onload= callback
	var image_reg = /src=\"(.*)\"/;
	var image_source = image_reg.exec(image_data);
	
	// The new html without the src= stuff; thats now in image_source[0]
	var new_image_data = image_data.replace(image_source[0],'');
	transitionImage(images[n], new_image_data, image_source);
}

// Fade the current image to black, update its contents with the new image
function transitionImage(image, content, source) {
	image.morph('opacity:0', 
		{ 	duration: 2.0,
			afterFinish: function() {
				updateImage(image, content, source);
			}
		}
	)
}

// Update the target image item in place. We must replace the innerHTML,
// but take care to (a) also update the id of the main div element and
// (b) also be careful adding the src= to the img so we can trap the onload=
// and hence not fadeUp the image until it is fully loaded.
function updateImage(image, content, source) {
	var newItem = new Element('p').update(content).down();
	var newImage = newItem.down().next();		// Should be the anchor tag
	var newImg = newImage.down();				// The img tag
	image.update(newImage);
	image.insert({bottom: newItem.down('p')});
	image.id = newItem.id;
	newImg.src = source[1];
	if (newImg.complete)
		fadeUpImage(image);
	else
		newImg.onload = function(){ fadeUpImage(image) }; 
}

function fadeUpImage(image) {
	image.morph('opacity:1', {duration: 2.0});
}

// Are all images loaded?
function imagesAreLoaded() {
	var images = $$('._random_image img'), status = 1;
	images.each(function(image, index) {
		if(!image.complete) status = 0;
	});
	return status;
}

// The currently displayed images in parameter format in
// order to exclude from the next server request
function currentImages() {
	var currentIDs = new Array;
	$('thumbnailList').childElements().each( function(e, i) {
		db_id = /^.*_(.*)/.exec(e.id);
		currentIDs.push("current[]=" + db_id[1]);
	});
	return currentIDs.join("&");
}

document.observe("dom:loaded", function() {setInterval("getRandomImage()", 5000);});