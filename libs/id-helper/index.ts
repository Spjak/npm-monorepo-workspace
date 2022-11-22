import { v4 as uuidv4 } from 'uuid'

export class IdHelper {
    static getRandomId() {
        return uuidv4()
    }
}