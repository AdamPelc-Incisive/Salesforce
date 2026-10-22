import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import FLOW_MESSENGER from '@salesforce/messageChannel/FlowMessenger__c';

export default class FlowMsgAction extends LightningElement {
    // ── Flow Inputs ──────────────────────────────────────────────────────────
    _recordId;
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.schedulePublish();
    }

    _action;
    @api
    get action() {
        return this._action;
    }
    set action(value) {
        this._action = value;
        this.schedulePublish();
    }

    _sessionId;
    @api
    get sessionId() {
        return this._sessionId;
    }
    set sessionId(value) {
        this._sessionId = value;
        this.schedulePublish();
    }

    _status;
    @api
    get status() {
        return this._status;
    }
    set status(value) {
        this._status = value;
        this.schedulePublish();
    }

    // ── Flow Output ──────────────────────────────────────────────────────────
    @api publishSuccess = false;

    // ── Internal ─────────────────────────────────────────────────────────────
    messageContext;
    _isConnected = false;
    _publishScheduled = false;
    _lastPublishedPayload;

    @wire(MessageContext)
    wiredMessageContext(context) {
        this.messageContext = context;
        this.schedulePublish();
    }

    // ── Lifecycle ────────────────────────────────────────────────────────────
    connectedCallback() {
        this._isConnected = true;
        this.schedulePublish();
    }

    disconnectedCallback() {
        this._isConnected = false;
        this._publishScheduled = false;
    }

    // ── Core ─────────────────────────────────────────────────────────────────
    schedulePublish() {
        if (!this._isConnected || this._publishScheduled) {
            return;
        }

        this._publishScheduled = true;
        Promise.resolve().then(() => {
            this._publishScheduled = false;
            if (this._isConnected) {
                this.publishMessage();
            }
        });
    }

    publishMessage() {
        // All Asset Management messages require these values. Waiting for the
        // complete payload avoids Flow input-setter ordering races and prevents
        // deselection events from advancing the listener flow.
        if (!this._recordId || !this._action || !this._sessionId || !this.messageContext) {
            return;
        }

        const message = {
            recordId: this._recordId,
            action: this._action,
            sessionId: this._sessionId,
            status: this._status || null
        };
        const payloadKey = JSON.stringify(message);
        if (payloadKey === this._lastPublishedPayload) {
            return;
        }

        try {
            publish(this.messageContext, FLOW_MESSENGER, message);
            this._lastPublishedPayload = payloadKey;
            this.publishSuccess = true;
            this.dispatchEvent(new FlowAttributeChangeEvent('publishSuccess', true));
        } catch (error) {
            this.publishSuccess = false;
            this.dispatchEvent(new FlowAttributeChangeEvent('publishSuccess', false));
            console.error('FlowMsgAction publish error:', error);
        }
    }
}