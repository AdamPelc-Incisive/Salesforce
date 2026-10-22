import { LightningElement, api, wire } from 'lwc';
import { subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import FLOW_MESSENGER from '@salesforce/messageChannel/FlowMessenger__c';

export default class FlowMsgReceiver extends LightningElement {
    // ── Flow Inputs ──────────────────────────────────────────────────────────
    @api filterByAction; // Only react to this action (leave blank for all)
    @api filterBySessionId; // Only react to this session ID (leave blank for all)
    @api ignoreAction; // Ignore messages with this action (e.g. a refresh broadcast this flow published itself)
    @api autoNavigate = false; // Automatically advance to next screen when message received
    @api allowRepeatMessages = false; // By default a repeat of the last identical message is suppressed. Set true when the same message should re-fire a reaction (e.g. an in-place refresh).

    // ── Flow Outputs ─────────────────────────────────────────────────────────
    @api receivedRecordId;
    @api receivedAction;
    @api receivedSessionId;
    @api receivedStatus;
    @api messageReceived = false;
    @api receivedCount = 0; // Increments on every accepted message; use as a reactive trigger source for screen actions.

    // ── Internal ─────────────────────────────────────────────────────────────
    @wire(MessageContext) messageContext;
    subscription = null;
    _lastMessageKey;
    _navigationPending = false;
    _navigationTimer;

    // ── Lifecycle ────────────────────────────────────────────────────────────
    connectedCallback() {
        this.subscription = subscribe(
            this.messageContext,
            FLOW_MESSENGER,
            (message) => this.handleMessage(message),
            { scope: APPLICATION_SCOPE }
        );
    }

    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
        if (this._navigationTimer) {
            clearTimeout(this._navigationTimer);
            this._navigationTimer = null;
        }
        this._navigationPending = false;
    }

    // ── Handler ──────────────────────────────────────────────────────────────
    handleMessage(message) {
        if (!message) {
            return;
        }
        if (this.filterByAction && message.action !== this.filterByAction) {
            return;
        }
        if (this.ignoreAction && message.action === this.ignoreAction) {
            return;
        }
        if (this.filterBySessionId && message.sessionId !== this.filterBySessionId) {
            return;
        }

        const messageKey = JSON.stringify({
            recordId: message.recordId || null,
            action: message.action || null,
            sessionId: message.sessionId || null,
            status: message.status || null
        });
        if (this._navigationPending) {
            return;
        }
        if (!this.allowRepeatMessages && messageKey === this._lastMessageKey) {
            return;
        }
        this._lastMessageKey = messageKey;

        this.receivedRecordId = message.recordId || null;
        this.receivedAction = message.action || null;
        this.receivedSessionId = message.sessionId || null;
        this.receivedStatus = message.status || null;
        this.messageReceived = true;
        this.receivedCount += 1;

        // Set the guard first so Flow visibility rules cannot mount a second
        // navigator while the remaining message outputs are propagating.
        this.dispatchEvent(new FlowAttributeChangeEvent('messageReceived', this.messageReceived));
        this.dispatchEvent(new FlowAttributeChangeEvent('receivedRecordId', this.receivedRecordId));
        this.dispatchEvent(new FlowAttributeChangeEvent('receivedAction', this.receivedAction));
        this.dispatchEvent(new FlowAttributeChangeEvent('receivedSessionId', this.receivedSessionId));
        this.dispatchEvent(new FlowAttributeChangeEvent('receivedStatus', this.receivedStatus));
        // Dispatched last so any screen action keyed on receivedCount re-fires
        // only after the other outputs are already in place.
        this.dispatchEvent(new FlowAttributeChangeEvent('receivedCount', this.receivedCount));

        if (this.autoNavigate) {
            this._navigationPending = true;
            // Let Flow process all output changes before it evaluates the next
            // element. A single timer also prevents duplicate LMS deliveries
            // from dispatching competing navigation events.
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this._navigationTimer = setTimeout(() => {
                this._navigationTimer = null;
                // Clear the guard once the navigation is dispatched so a
                // surviving instance (e.g. a screen that loops back to itself)
                // can still react to a later, genuinely new message.
                this._navigationPending = false;
                this.dispatchEvent(new FlowNavigationNextEvent());
            }, 0);
        }
    }
}