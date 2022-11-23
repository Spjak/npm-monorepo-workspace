import { format as prettyFormat } from 'pretty-format'
import { IdHelper } from 'id-helper'

console.log(prettyFormat({userId: IdHelper.getRandomId()}))
