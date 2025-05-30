'use strict';
/**
 * Adds the "vgc-round-active" class to the round content matching the given index.
 * @param {string} aIndex 
 * @returns {void}
 */
function activateContent(aIndex) {
  let content = document.getElementById('round-' + aIndex + '-content');
  if (!content) return console.error('Could not find the round ' + aIndex + '.');
  return content.classList.add('vgc-round-active');
}
/**
 * Removes the "vgc-round-active" class from any element that has it.
 */
function removeActiveRounds() {
  let activeRounds = document.getElementsByClassName('vgc-round-active');
  while (activeRounds.length > 0)
    activeRounds[0].classList.remove('vgc-round-active');
}
/**
 * Click event handler that adds the "vgc-round-active" to the clicked round header and to the related content.
 * @param {Event} aEvent 
 * @returns {void}
 */
function activateRound(aEvent) {
  if (aEvent.target.classList.contains('vgc-round-active')) return;
  removeActiveRounds();
  aEvent.target.classList.add('vgc-round-active');
  return activateContent(aEvent.target.getAttribute('index'));
}
/**
 * Load event handler that scans all the round headers and attaches the click listener to them.
 * If one header does have the "vgc-round-active" class, it activates the related content.
 * @returns {void}
 */
function initializeRounds() {
  let headers = document.getElementsByClassName('vgc-round-header');
  let activeHeader = null;
  for (let item of headers) {
    item.addEventListener('click', activateRound);
    if (item.classList.contains('vgc-round-active'))
      if (activeHeader) return console.error('Multiple active round headers');
      else activeHeader = item;
  }
  return activateContent(activeHeader.getAttribute('index'));
}
  
document.addEventListener('DOMContentLoaded', initializeRounds);