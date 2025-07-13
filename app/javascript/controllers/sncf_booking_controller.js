import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal", "widget"]
  static values = {
    origin: String,
    destination: String,
    date: String,
    time: String
  }

  connect() {
    this.isWidgetReady = false;
    this.currentWidgetInstance = null;

    // Listen for widget ready event
    this.widgetReadyHandler = this.handleWidgetReady.bind(this);
    document.addEventListener("IvtsWidgetsExternal.Booking.Ready", this.widgetReadyHandler);

    // Load SNCF script if not already loaded
    this.loadSncfScript();
  }

  disconnect() {
    document.removeEventListener("IvtsWidgetsExternal.Booking.Ready", this.widgetReadyHandler);

    // Clean up widget instance if needed
    if (this.currentWidgetInstance) {
      this.destroyWidget();
    }
  }

  loadSncfScript() {
    // Check if script is already loaded or loading
    if (window.sncfScriptLoaded || window.sncfScriptLoading) {
      // If already loaded, check if widget is ready
      if (window.sncfScriptLoaded && window.IvtsWidgetsExternal) {
        this.isWidgetReady = true;
        this.bookingWidget = window.IvtsWidgetsExternal?.Booking;
      }
      return;
    }

    // Check if script already exists in DOM
    const existingScript = document.querySelector('script[src*="web-widgets-external.js"]');
    if (existingScript) {
      window.sncfScriptLoading = true;
      return;
    }

    // Mark as loading to prevent multiple loads
    window.sncfScriptLoading = true;

    // Create and load script
    const script = document.createElement('script');
    script.src = 'https://www.sncf-connect.com/widget-external/web-widgets-external.js';
    script.async = true;
    script.defer = true;

    script.onload = () => {
      window.sncfScriptLoaded = true;
      window.sncfScriptLoading = false;
    };

    script.onerror = () => {
      window.sncfScriptLoading = false;
      console.error('Failed to load SNCF widget script');
    };

    // Add to head to ensure it loads early
    document.head.appendChild(script);
  }

  handleWidgetReady(event) {
    this.isWidgetReady = true;
    this.bookingWidget = event.detail;
  }

  openModal(event) {
    event.preventDefault();

    // Get station names from data attributes
    const origin = event.currentTarget.dataset.origin;
    const destination = event.currentTarget.dataset.destination;
    const date = event.currentTarget.dataset.date;
    const time = event.currentTarget.dataset.time;

    // Update values
    this.originValue = origin;
    this.destinationValue = destination;
    this.dateValue = date;
    this.timeValue = time;

    // Track analytics event
    this.trackBookingModalOpen(origin, destination);

    // Show modal
    this.modalTarget.classList.remove("hidden");
    document.body.classList.add("overflow-hidden");

    // Initialize or reinitialize widget
    this.initializeWidget();
  }

  closeModal(event) {
    if (event) {
      event.preventDefault();
    }

    this.modalTarget.classList.add("hidden");
    document.body.classList.remove("overflow-hidden");

    // Destroy current widget instance to clean up
    this.destroyWidget();
  }

  initializeWidget() {
    // Check if widget is available but not marked as ready (missed event)
    if (!this.isWidgetReady && window.IvtsWidgetsExternal?.Booking) {
      this.isWidgetReady = true;
      this.bookingWidget = window.IvtsWidgetsExternal.Booking;
    }

    if (!this.isWidgetReady || !this.bookingWidget) {
      // If widget not ready, try again in a short delay
      setTimeout(() => this.initializeWidget(), 100);
      return;
    }

    // Clear existing widget content
    this.widgetTarget.innerHTML = "";

    // Create unique container ID for this instance
    const containerId = `booking-widget-${Date.now()}`;
    this.widgetTarget.innerHTML = `<div id="${containerId}"></div>`;

    // Initialize widget with current values
    const widgetConfig = {
      isOneWay: true,
      titleIndex: 2,
      isInModal: true,
      origin: {
        defaultValue: this.originValue,
        isDisabled: true
      },
      destination: {
        defaultValue: this.destinationValue,
        isDisabled: true
      },
      tracking: {
        wizalyQueryParameters: "wiz_medium=part&wiz_source=velotrain&wiz_campaign=fr_conv_widget_contenu_filrouge_tr-multiproduit__mk_202405&wiz_content=fr",
      },
    };

    // Add date and time if provided
    if (this.dateValue) {
      widgetConfig.outwardDate = { defaultValue: this.dateValue };
    }

    try {
      this.currentWidgetInstance = this.bookingWidget.init(containerId, widgetConfig);
    } catch (error) {
      console.error("Failed to initialize SNCF booking widget:", error);
    }
  }

  destroyWidget() {
    if (this.currentWidgetInstance) {
      try {
        // Try to destroy the widget instance if it has a destroy method
        if (typeof this.currentWidgetInstance.destroy === 'function') {
          this.currentWidgetInstance.destroy();
        }
      } catch (error) {
        console.warn("Error destroying widget instance:", error);
      }
      this.currentWidgetInstance = null;
    }

    // Clear widget container
    if (this.hasWidgetTarget) {
      this.widgetTarget.innerHTML = "";
    }
  }

  // Handle backdrop click to close modal
  handleBackdropClick(event) {
    // Close modal if clicking on the modal backdrop (not the modal content)
    if (event.target === this.modalTarget || event.target.classList.contains('bg-black')) {
      this.closeModal();
    }
  }

  // Handle escape key to close modal
  handleKeydown(event) {
    if (event.key === "Escape") {
      this.closeModal();
    }
  }

  // Track booking modal open event with Plausible
  trackBookingModalOpen(origin, destination) {
    // Check if Plausible is available
    if (typeof window.plausible === 'function') {
      try {
        window.plausible('SNCF Booking Modal Opened', {
          props: {
            origin: origin,
            destination: destination,
          }
        });
      } catch (error) {
        console.warn('Failed to track booking modal event:', error);
      }
    }
  }
}
