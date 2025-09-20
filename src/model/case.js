export class Case {
    constructor(id, userId, title, storagePath, feedback, score, raw, timeStamps, userComment) {
        this.id = id
        this.userId = userId
        this.title = title
        this.storagePath = storagePath
        this.feedback = feedback
        this.score = score
        this.raw = raw
        this.timeStamps = timeStamps
        this.userComment = userComment
    }
}