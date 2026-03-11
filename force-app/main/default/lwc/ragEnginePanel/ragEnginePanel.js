import { LightningElement, api, track } from 'lwc';
import generateCaseResolution from '@salesforce/apex/RAGEngineController.generateCaseResolution';
import sendCaseEmail from '@salesforce/apex/RAGEngineController.sendCaseEmail';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RagEnginePanel extends LightningElement {
    @api recordId;
    @track isLoading = false;
    @track isSending = false;
    @track generatedReply = '';
    @track errorMessage = '';

    async handleGenerate() {
        this.isLoading = true;
        this.generatedReply = '';
        this.errorMessage = '';
        try {
            const result = await generateCaseResolution({ caseId: this.recordId });
            this.generatedReply = result;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Reply Generated!',
                message: 'AI reply drafted from Knowledge Articles',
                variant: 'success'
            }));
        } catch (error) {
            this.errorMessage = error.body?.message || 'An error occurred';
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: this.errorMessage,
                variant: 'error'
            }));
        } finally {
            this.isLoading = false;
        }
    }

    handleReplyEdit(event) {
        this.generatedReply = event.target.value;
    }

    async handleSendEmail() {
        this.isSending = true;
        try {
            await sendCaseEmail({
                caseId: this.recordId,
                emailBody: this.generatedReply
            });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Email Sent!',
                message: 'Reply sent to customer successfully',
                variant: 'success'
            }));
            this.generatedReply = '';
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Send Failed',
                message: error.body?.message || 'Could not send email',
                variant: 'error'
            }));
        } finally {
            this.isSending = false;
        }
    }

    handleCopy() {
        navigator.clipboard.writeText(this.generatedReply);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Copied!',
            variant: 'success'
        }));
    }
}