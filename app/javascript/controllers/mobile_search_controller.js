import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container", "resultsContainer"];
  static values = { collapsed: Boolean };

  connect() {
    this.initialSetup();
    this.bindTouchEvents();

    // Handle window resize
    this.handleResize = this.handleResize.bind(this);
    window.addEventListener('resize', this.handleResize);
  }

  disconnect() {
    this.unbindTouchEvents();
    window.removeEventListener('resize', this.handleResize);
  }

  initialSetup() {
    // Set initial state based on mobile or desktop
    if (this.isMobile()) {
      this.collapsedValue = true;
      this.updateContainerPosition();
    }
  }

  toggle() {
    this.collapsedValue = !this.collapsedValue;
    this.updateContainerPosition();
    this.updateButtonVisibility();
  }

  updateContainerPosition() {
    if (!this.isMobile()) return;

    const container = this.containerTarget;
    const offset = this.getCollapsedOffset();


    if (this.collapsedValue) {
      container.style.transform = `translateY(${offset}px)`;
      // Prevent scrolling when collapsed
      if (this.hasResultsContainerTarget) {
        this.resultsContainerTarget.style.overflow = 'hidden';
        this.resultsContainerTarget.style.pointerEvents = 'none';
      }
    } else {
      container.style.transform = 'translateY(10px)';
      // Re-enable scrolling when expanded
      if (this.hasResultsContainerTarget) {
        this.resultsContainerTarget.style.overflow = '';
        this.resultsContainerTarget.style.pointerEvents = '';
      }
    }
  }

  getCollapsedOffset() {
    return window.innerHeight - 60;
  }

  isMobile() {
    return window.innerWidth < 768; // md breakpoint
  }

  // Touch event handling for drag functionality
  bindTouchEvents() {
    if (!this.isMobile()) return;

    this.touchStartY = 0;
    this.touchCurrentY = 0;
    this.isDragging = false;
    this.startTransform = 0;

    this.handleTouchStart = this.handleTouchStart.bind(this);
    this.handleTouchMove = this.handleTouchMove.bind(this);
    this.handleTouchEnd = this.handleTouchEnd.bind(this);

    this.containerTarget.addEventListener('touchstart', this.handleTouchStart, { passive: false });
    this.containerTarget.addEventListener('touchmove', this.handleTouchMove, { passive: false });
    this.containerTarget.addEventListener('touchend', this.handleTouchEnd, { passive: false });
  }

  unbindTouchEvents() {
    if (this.containerTarget) {
      this.containerTarget.removeEventListener('touchstart', this.handleTouchStart);
      this.containerTarget.removeEventListener('touchmove', this.handleTouchMove);
      this.containerTarget.removeEventListener('touchend', this.handleTouchEnd);
    }
  }

  handleTouchStart(e) {

    const target = e.target;

    // Explicitly exclude interactive elements
    const isFormElement = ['INPUT', 'SELECT', 'TEXTAREA', 'BUTTON'].includes(target.tagName);
    const isInCombobox = target.closest('[data-hw-combobox-target]') || target.closest('.hw-combobox');
    const isButton = target.closest('button');
    const isResultsArea = this.hasResultsContainerTarget && this.resultsContainerTarget.contains(target);

    // Don't interfere with any interactive elements
    if (isFormElement || isInCombobox || isButton || isResultsArea) {
      return;
    }

    // Only allow dragging from explicit drag handle areas
    const isDragHandle = target.closest('.drag-handle');

    if (isDragHandle) {
      this.touchStartY = e.touches[0].clientY;
      this.isDragging = true;
      this.startTransform = this.getCurrentTransform();

      // Disable transitions during drag
      this.containerTarget.style.transition = 'none';
    } else {
    }
  }

  handleTouchMove(e) {
    if (!this.isDragging) return;


    // Only prevent default if we're actually dragging the container
    e.preventDefault();
    e.stopPropagation();

    this.touchCurrentY = e.touches[0].clientY;
    const deltaY = this.touchCurrentY - this.touchStartY;
    const newTransform = this.startTransform + deltaY;

    // Constrain the movement
    const minTransform = 0;
    const maxTransform = this.getCollapsedOffset();
    const constrainedTransform = Math.max(minTransform, Math.min(maxTransform, newTransform));

    this.containerTarget.style.transform = `translateY(${constrainedTransform}px)`;
  }

  handleTouchEnd() {
    if (!this.isDragging) return;

    this.isDragging = false;

    // Re-enable transitions
    this.containerTarget.style.transition = '';

    const deltaY = this.touchCurrentY - this.touchStartY;
    const velocity = Math.abs(deltaY);
    const threshold = 50; // minimum distance to trigger toggle


    // Determine if we should toggle based on direction and velocity
    if (velocity > threshold) {
      if (deltaY > 0 && !this.collapsedValue) {
        // Dragging down from expanded -> collapse
        this.collapsedValue = true;
      } else if (deltaY < 0 && this.collapsedValue) {
        // Dragging up from collapsed -> expand
        this.collapsedValue = false;
      }
    } else {
      // Small movement - snap to nearest state
      const currentTransform = this.getCurrentTransform();
      const midpoint = this.getCollapsedOffset() / 2;
      this.collapsedValue = currentTransform > midpoint;
    }

    this.updateContainerPosition();
  }

  getCurrentTransform() {
    const style = window.getComputedStyle(this.containerTarget);
    const matrix = style.transform;

    if (matrix === 'none') return 0;

    const values = matrix.match(/matrix\((.+)\)/);
    if (values) {
      const matrixValues = values[1].split(', ');
      return parseFloat(matrixValues[5]) || 0; // translateY value
    }

    return 0;
  }

  // Handle window resize
  handleResize() {
    if (this.isMobile()) {
      this.updateContainerPosition();
    } else {
      // Reset for desktop
      this.containerTarget.style.transform = '';
    }
  }
}
