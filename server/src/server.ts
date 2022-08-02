import * as express from 'express'
import { Request, Response } from 'express'
import { execSync,spawnSync,spawn,exec } from 'child_process'
import * as cors from 'cors'
import * as fs from 'fs'
import * as path from 'path'

const app = express()
app.use(cors())
app.use(express.json({type: '*/*'}))

app.get('/', (req: Request, res: Response) => {
    res.sendStatus(200)
})

app.get('/tracks', (req: Request, res: Response) => {
    const tracks = fs.readdirSync('./tracks')
    const tracksWithoutExtension = tracks.map(track => track.split('.').slice(0, track.split('.').length-1).join('.'))
    res.status(200).json(tracksWithoutExtension)
})

app.post('/download', async (req: Request, res: Response) => {
    if(!req.body.url || !req.body.name) return res.status(400)
    let { url, name } = req.body
    name = name.replace(/\s/g, '_')
    const filepath = path.join(__dirname,'..','raw',name+'.mp3')
    if(fs.existsSync(filepath)) return res.sendStatus(409)
    execSync(`youtube-dl -x --audio-format mp3 -o "${filepath}" ${url}`)
    execSync(`ffmpeg -i "${filepath}" -hide_banner  -loglevel error -y -filter:a loudnorm "${path.join(__dirname,'..','raw',name+'.wav')}"`)
    //fs.rmSync(filepath)
    
    execSync(`java -jar "${path.join(__dirname,'..','dfpwmconverter.jar')}" "${path.join(__dirname,'..','raw',name+'.wav')}" "${path.join(__dirname,'..','tracks',name+'.dfpwm')}"`)
    fs.rmSync(path.join(__dirname,'..','raw',name+'.wav'))
    res.sendStatus(200)
})

app.get('/duration/:name', async (req: Request, res: Response) => {
    const name = req.params.name
    const filepath = path.join(__dirname,'..','raw',name+'.mp3')
    if(!fs.existsSync(filepath)) return res.sendStatus(404)

    /*const duration = await getAudioDurationInSeconds(filepath)
    res.status(200).send(duration)*/
    let output = execSync('ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1 "' + filepath + '"').toString().trim()

    output = output.split('=')[1]
    let duration = parseFloat(output)
    duration = Math.round(duration)
    res.send(duration+"")
})

app.use('/tracks', express.static('./tracks'))

app.listen(9515,()=>console.log('listening on port 9515'))
Math.floor