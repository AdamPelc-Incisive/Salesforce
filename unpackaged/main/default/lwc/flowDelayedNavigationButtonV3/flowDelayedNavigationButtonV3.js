import { api, LightningElement } from 'lwc';
import {
    FlowAttributeChangeEvent,
    FlowNavigationNextEvent
} from 'lightning/flowSupport';

const DEFAULT_DELAY_MS = 250;
const MAX_DELAY_MS = 2000;

export default class FlowDelayedNavigationButtonV3 extends LightningElement {
    @api buttonLabel = 'Continue';
    @api actionValue = 'next';
    @api iconName;
    @api iconPosition = 'left';
    @api variant = 'brand';
    @api alignment = 'right';
    @api delayMs = DEFAULT_DELAY_MS;
    @api availableActions = [];

    _isNavigating = false;
    _value;

    @api
    get value() {
        return this._value;
    }

    set value(value) {
        this._value = value;
    }

    get alignmentClass() {
        const alignmentClasses = {
            center: 'slds-grid_align-center',
            left: 'slds-grid_align-start',
            right: 'slds-grid_align-end'
        };
        const normalizedAlignment = (this.alignment || 'right').toLowerCase();

        return `slds-grid ${alignmentClasses[normalizedAlignment] || alignmentClasses.right}`;
    }

    get normalizedDelay() {
        const delay = Number(this.delayMs);

        if (!Number.isFinite(delay)) {
            return DEFAULT_DELAY_MS;
        }

        return Math.min(Math.max(delay, 0), MAX_DELAY_MS);
    }

    get normalizedIconPosition() {
        return (this.iconPosition || '').toLowerCase() === 'right'
            ? 'right'
            : 'left';
    }

    handlePointerDown(event) {
        event.currentTarget.focus();
    }

    async handleClick() {
        if (this._isNavigating) {
            return;
        }

        this._isNavigating = true;

        // Do not publish the output until the Repeater has committed its inputs.
        // Publishing before this wait causes Flow reactivity to restore defaults.
        await this.waitForScreenInputs();

        this._value = this.actionValue;
        this.dispatchEvent(
            new FlowAttributeChangeEvent('value', this._value)
        );

        if (this.availableActions.includes('NEXT')) {
            this.dispatchEvent(new FlowNavigationNextEvent());
            return;
        }

        this._isNavigating = false;
    }

    async waitForScreenInputs() {
        await new Promise((resolve) => {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            requestAnimationFrame(() => requestAnimationFrame(resolve));
        });
        await new Promise((resolve) => {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(resolve, this.normalizedDelay);
        });
    }
}