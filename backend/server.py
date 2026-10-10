#!/usr/bin/env python3
"""
圈子社区 (Campus Circle) — lightweight REST backend.

Standard-library only (no external deps) so it runs anywhere.
Data is persisted to backend/data/db.json.

Run:  python3 backend/server.py --port 8787
"""
import argparse
import json
import os
import threading
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

ROOT = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(ROOT, "data")
DB_PATH = os.path.join(DATA_DIR, "db.json")
LOCK = threading.Lock()

NOW = int(time.time() * 1000)
H = 3600_000
D = 86_400_000

# Business rules (from design handoff)
CORE_MAX = 2          # 头像 / 用户名 / 性别 修改次数
OTHER_MAX = 5         # 其它资料修改次数
CHAT_PRE_REPLY_MAX = 2  # 私聊：对方回复前最多发送 2 条
RECALL_WINDOW_MS = 3 * 60_000  # 撤回窗口 3 分钟
SERVICE_RETENTION_MS = 90 * D  # 客服记录 App 端保留 90 天


def new_id(prefix: str) -> str:
    return prefix + uuid.uuid4().hex[:10]


def seed_db() -> dict:
    return {
        "members": {
            "800123": {"uid": "800123", "name": "我的昵称", "gender": "f", "avatar": "", "bgUrl": "",
                       "bio": "热爱生活，喜欢分享校园日常。", "ip": "吉隆坡", "status": "ok",
                       "fields": {"company": "", "job": "学生", "role": "", "wechat": "", "whatsapp": "", "fb": "", "ig": ""},
                       "following": ["allanliu6", "weichen", "shier"], "followers": ["allanliu6", "yy2026"], "likes": 36,
                       "modifiedAt": 0},
        },
        "home": {
            "slides": [
                {"seed": "home-hero-1", "grad": ["#7C3AED", "#4F46E5"], "title": "示例主题一", "subtitle": "本周精选", "image": ""},
                {"seed": "home-hero-2", "grad": ["#F97316", "#EC4899"], "title": "示例主题二", "subtitle": "开学季推荐", "image": ""},
                {"seed": "home-hero-3", "grad": ["#10B981", "#0EA5E9"], "title": "示例主题三", "subtitle": "热门活动", "image": ""},
            ],
            "hotCircles": [
                {"id": "res", "label": "学习资源交流", "seed": "hc-res"},
                {"id": "team", "label": "FIND COUPLE IN TEAMWORK", "seed": "hc-team"},
                {"id": "art", "label": "艺术设计", "seed": "hc-art"},
                {"id": "music", "label": "音乐社团", "seed": "hc-music"},
                {"id": "gym", "label": "健身俱乐部", "seed": "hc-gym"},
                {"id": "study", "label": "University Study Life Makes Easy", "seed": "hc-study"},
                {"id": "yy", "label": "兴趣组团YY", "seed": "hc-yy"},
                {"id": "car", "label": "汽车配件", "seed": "hc-car"},
            ],
            "hotForums": [
                {"id": "course", "label": "入门课程", "seed": "hf-course", "tint": "#EC4899"},
                {"id": "abroad", "label": "海外留学", "seed": "hf-abroad", "tint": "#38BDF8"},
                {"id": "major", "label": "大学学科", "seed": "hf-major", "tint": "#7C3AED"},
                {"id": "video", "label": "Video Edition", "seed": "hf-video", "tint": "#7C3AED"},
                {"id": "stream", "label": "Streaming", "seed": "hf-stream", "tint": "#38BDF8"},
                {"id": "digital", "label": "Digital World", "seed": "hf-digital", "tint": "#7C3AED"},
            ],
        },
        # 圈子分类：一级 → 二级
        "circles": [
            {"id": "study", "label": "学习成长", "children": [
                {"id": "res", "label": "学习资源交流", "sub": "我有酒你有故事吗?"},
                {"id": "study", "label": "University Study Life Makes Easy", "sub": "Study smart"},
                {"id": "abroad", "label": "留学互助", "sub": "一起走向世界"}]},
            {"id": "life", "label": "校园生活", "children": [
                {"id": "gym", "label": "健身俱乐部", "sub": "自律给我自由"},
                {"id": "music", "label": "音乐社团", "sub": "用音乐连接彼此"},
                {"id": "art", "label": "艺术设计", "sub": "灵感无处不在"}]},
            {"id": "social", "label": "兴趣社交", "children": [
                {"id": "yy", "label": "兴趣组团YY", "sub": "做一个沙雕，快乐天天有"},
                {"id": "team", "label": "FIND COUPLE IN TEAMWORK", "sub": "Find your teammate"},
                {"id": "car", "label": "汽车配件", "sub": "车友交流"}]},
        ],
        "topics": [
            {"id": "t1", "name": "开学第一周怎么过？", "category": "入门课程", "posts": 128},
            {"id": "t2", "name": "留学申请时间线分享", "category": "海外留学", "posts": 96},
            {"id": "t3", "name": "计算机专业选课攻略", "category": "大学学科", "posts": 74},
            {"id": "t4", "name": "剪辑软件推荐", "category": "Video Edition", "posts": 52},
            {"id": "t5", "name": "直播设备入门", "category": "Streaming", "posts": 38},
            {"id": "t6", "name": "AI 工具大合集", "category": "Digital World", "posts": 211},
        ],
        "posts": [
            {"id": "p1", "type": "circle", "author": "segi asia marketing (SAM)", "authorUid": "800001", "text": "开学季来啦！本学期第一个学习圈已经开放报名，欢迎大家一起来交流学习心得，共同进步 📚",
             "images": ["f1a", "f1b"], "hasVideo": False, "poll": None, "circle": {"id": "res", "label": "学习资源交流"}, "topic": None,
             "likes": 5, "comments": 7, "status": "approved", "ts": NOW - 3 * D},
            {"id": "p2", "type": "circle", "author": "allanliu6", "authorUid": "800002", "text": "今天分享一份学习计划表，希望对刚开学的同学有帮助。",
             "images": ["f3a", "f3b", "f3c"], "hasVideo": False,
             "poll": {"question": "你每天学习多久？", "options": [{"text": "1 小时以内", "votes": 6}, {"text": "1–3 小时", "votes": 14}, {"text": "3 小时以上", "votes": 9}]},
             "circle": {"id": "res", "label": "学习资源交流"}, "topic": None, "likes": 6, "comments": 8, "status": "approved", "ts": NOW - 5 * D},
            {"id": "p3", "type": "forum", "author": "shier", "authorUid": "800003", "text": "刚开始大学生活，学业与生活平衡的一些小心得，希望对大家有用。",
             "images": [], "hasVideo": False, "poll": None, "circle": None, "topic": {"id": "t1", "name": "开学第一周怎么过？"},
             "likes": 3, "comments": 3, "status": "approved", "ts": NOW - 6 * D},
        ],
        "events": [
            {"id": "uev-1", "title": "读书会 · 十月共读《人类简史》", "date": "2026-10-20", "time": "19:30", "place": "吉隆坡中央图书馆",
             "detail": "每周一次线下共读，欢迎新朋友加入。", "seed": "uev-1", "author": "allanliu6", "baseViews": 0, "views": 0, "signups": [], "status": "approved"},
            {"id": "ev1", "title": "示例活动一 · 校园周末音乐节", "date": "2026-12-15", "time": "19:00", "place": "示例地点 · 由后台配置",
             "detail": "这里是活动详情示例。管理员在后台发布活动后，用户在此看到完整介绍、时间、地点与图片。", "seed": "ev1",
             "author": "segi asia marketing (SAM)", "baseViews": 78, "views": 0, "signups": ["allanliu6", "shier", "mymuse60", "myunisocial", "weichen"], "status": "approved"},
            {"id": "ev2", "title": "示例活动二 · 编程马拉松", "date": "2025-01-30", "time": "09:00", "place": "创新中心 3 楼",
             "detail": "48 小时团队编程挑战，欢迎所有专业同学报名组队。", "seed": "ev2", "author": "segi asia marketing (SAM)", "baseViews": 7, "views": 0, "signups": ["jacky"], "status": "approved"},
            {"id": "ev3", "title": "示例活动三 · 摄影分享会", "date": "2025-01-13", "time": "14:30", "place": "图书馆多功能厅",
             "detail": "分享你的摄影作品和拍摄心得，现场有专业老师点评。", "seed": "ev3", "author": "segi asia marketing (SAM)", "baseViews": 3, "views": 0, "signups": ["future", "yy", "segi"], "status": "approved"},
        ],
        "feedback": [
            {"id": "fb1", "uid": "800123", "cat": "circle", "subject": "关于登录问题的反馈", "desc": "登录后偶尔会自动退出，需要重新输入密码。", "contact": "sam@example.com", "images": [],
             "ts": NOW - 30 * D, "status": "done",
             "replies": [{"id": "r1", "text": "你好，感谢你的反馈。登录异常问题已在最新版本中修复，请更新后重试。如仍有问题，请联系在线客服。", "operator": "客服 · 张老师", "ts": NOW - 29 * D, "images": []}]},
            {"id": "fb2", "uid": "800123", "cat": "other", "subject": "建议增加深色模式", "desc": "晚上使用时屏幕太亮，希望增加深色模式。", "contact": "微信 sam2026", "images": [],
             "ts": NOW - 8 * D, "status": "doing",
             "replies": [{"id": "r2", "text": "感谢你的建议！深色模式已列入下一版本开发计划，届时会通过系统通知告知你。", "operator": "产品经理 · 李经理", "ts": NOW - 6 * D, "images": []}]},
        ],
        "notifications": [
            {"id": "n1", "title": "社区规范更新", "body": "为营造良好的社区氛围，我们更新了《社区规范》，请大家文明发言、友善交流。违反规范的内容将被删除。", "images": [], "ts": NOW - 3 * D},
            {"id": "n2", "title": "新版本上线", "body": "APP 已更新至最新版本：新增短视频频道、圈子分享卡片，修复了若干已知问题。", "images": [], "ts": NOW - 1 * D},
            {"id": "n3", "title": "国庆假期客服时间", "body": "国庆假期期间（10/1 – 10/7），在线客服服务时间调整为每天 10:00 – 18:00，感谢理解。", "images": [], "ts": NOW - 4 * H},
        ],
        "service": {
            "800123": [
                {"id": "s1", "who": "agent", "kind": "text", "text": "你好，这里是官方客服，请问有什么可以帮您？", "ts": NOW - 20 * 60_000},
                {"id": "s2", "who": "user", "kind": "text", "text": "请问怎么创建一个新圈子？", "ts": NOW - 12 * 60_000},
                {"id": "s3", "who": "agent", "kind": "text", "text": "您好，圈子由管理员在后台创建；您可以在「反馈信息」中提交圈子申请，审核通过后即可发布。", "ts": NOW - 10 * 60_000},
            ]
        },
        "chats": {
            "800123": {
                "allanliu6": {"name": "allanliu6", "gender": "f", "msgs": [
                    {"id": "c1", "from": "allanliu6", "kind": "text", "text": "很高兴认识你，欢迎随时聊聊", "ts": NOW - 2 * H}]},
                "weichen": {"name": "weichen", "gender": "m", "msgs": [
                    {"id": "c2", "from": "800123", "kind": "text", "text": "Hi, thanks for sharing the notes!", "ts": NOW - 4 * H},
                    {"id": "c3", "from": "weichen", "kind": "text", "text": "Thanks for the reply, appreciate it.", "ts": NOW - 3 * H}]},
                "yy2026": {"name": "兴趣组团YY", "gender": "f", "msgs": [
                    {"id": "c4", "from": "yy2026", "kind": "text", "text": "一起来玩呀，周末有活动", "ts": NOW - 1 * D}]},
                "shier": {"name": "十二", "gender": "m", "msgs": [
                    {"id": "c5", "from": "shier", "kind": "text", "text": "收到，稍后联系你", "ts": NOW - 4 * D}]},
            }
        },
        "unread": {
            "800123": {"share": 1, "feedback": 2, "sysnotify": 3, "service": 2, "users": {"allanliu6": 5, "weichen": 1, "yy2026": 2}}
        },
        "profileReviews": [],
        "legal": {
            "rules": {"title": "发帖规则", "sections": [
                {"h": "一、基本原则", "p": "遵守法律法规，尊重他人，禁止发布违法、色情、暴力、谣言等内容。"},
                {"h": "二、内容要求", "p": "帖子需与所选圈子 / 话题相关；图片每张不超过 500KB，视频不超过 5MB 或 60 秒。"},
                {"h": "三、审核机制", "p": "所有帖子提交后进入待审核状态，管理员审核通过后方可展示。"},
                {"h": "四、违规处理", "p": "违反规则的帖子将被删除，情节严重者将被禁言或停用帐户。"}]},
            "disclaimer": {"title": "免责声明", "sections": [
                {"h": "", "p": "本平台内容由用户自行发布，不代表平台立场。请用户自行甄别信息真伪，平台不对由此产生的任何损失承担责任。"}]},
        },
    }


class DB:
    def __init__(self):
        os.makedirs(DATA_DIR, exist_ok=True)
        if os.path.exists(DB_PATH):
            with open(DB_PATH, "r", encoding="utf-8") as f:
                self.data = json.load(f)
        else:
            self.data = seed_db()
            self.save()

    def save(self):
        tmp = DB_PATH + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(self.data, f, ensure_ascii=False, indent=1)
        os.replace(tmp, DB_PATH)


db = DB()


class ApiError(Exception):
    def __init__(self, status, msg):
        super().__init__(msg)
        self.status = status
        self.msg = msg


# ───────────────────────── handlers ─────────────────────────

def h_health(_q, _b, _p):
    return {"ok": True, "ts": int(time.time() * 1000)}


def h_home(_q, _b, _p):
    return db.data["home"]


def h_circles(_q, _b, _p):
    return db.data["circles"]


def h_topics(_q, _b, _p):
    return db.data["topics"]


def h_legal(_q, _b, p):
    key = p.get("key", "rules")
    if key not in db.data["legal"]:
        raise ApiError(404, "not found")
    return db.data["legal"][key]


def h_events(_q, _b, _p):
    return [e for e in db.data["events"] if e.get("status") == "approved" and not e.get("deleted")]


def _event(eid):
    for e in db.data["events"]:
        if e["id"] == eid:
            return e
    raise ApiError(404, "event not found")


def h_event(_q, _b, p):
    return _event(p["id"])


def h_event_view(_q, _b, p):
    e = _event(p["id"])
    e["views"] = e.get("views", 0) + 1
    db.save()
    return e


def h_event_join(_q, b, p):
    e = _event(p["id"])
    uid = str(b.get("uid", ""))
    if not uid:
        raise ApiError(400, "uid required")
    key = "me" if uid == "800123" else uid
    if key in e["signups"]:
        e["signups"].remove(key)
        joined = False
    else:
        e["signups"].append(key)
        joined = True
    db.save()
    return {"joined": joined, "event": e}


def h_event_submit(_q, b, _p):
    for k in ("title", "date", "place", "detail"):
        if not str(b.get(k, "")).strip():
            raise ApiError(400, f"{k} required")
    ev = {"id": new_id("uev-"), "title": b["title"].strip(), "date": b["date"], "time": b.get("time", ""),
          "place": b["place"].strip(), "detail": b["detail"].strip(), "seed": new_id("ev"), "author": b.get("author", "用户"),
          "baseViews": 0, "views": 0, "signups": [], "status": "pending", "ts": int(time.time() * 1000)}
    db.data["events"].append(ev)
    db.save()
    return ev


def h_posts(q, _b, _p):
    t = q.get("type")
    uid = q.get("uid")
    out = []
    for p in db.data["posts"]:
        if t and p["type"] != t:
            continue
        if p.get("deleted"):
            continue
        # own posts visible to the author regardless of status
        if p["status"] != "approved" and p.get("authorUid") != uid:
            continue
        out.append(p)
    out.sort(key=lambda x: x["ts"], reverse=True)
    return out


def h_post_create(_q, b, _p):
    ptype = b.get("type")
    if ptype not in ("circle", "forum"):
        raise ApiError(400, "type must be circle|forum")
    text = str(b.get("text", "")).strip()
    if not text and not b.get("images") and not b.get("hasVideo"):
        raise ApiError(400, "内容不能为空")
    if len(text) > 2000:
        raise ApiError(400, "内容超过 2000 字")
    if ptype == "circle" and not b.get("circle"):
        raise ApiError(400, "请选择圈子")
    if ptype == "forum" and not b.get("topic"):
        raise ApiError(400, "请选择话题")
    if not b.get("rulesAgreed", False):
        raise ApiError(400, "请先同意《发帖规则》")
    images = list(b.get("images") or [])[:8]
    poll = b.get("poll")
    if poll:
        opts = [o for o in (poll.get("options") or []) if str(o.get("text", "")).strip()]
        if not str(poll.get("question", "")).strip() or len(opts) < 2:
            raise ApiError(400, "投票需要标题和至少 2 个选项")
        poll = {"question": poll["question"].strip()[:40], "options": [{"text": o["text"].strip()[:20], "votes": 0} for o in opts[:5]]}
    post = {"id": new_id("p"), "type": ptype, "author": b.get("author", "我的昵称"), "authorUid": str(b.get("uid", "800123")),
            "text": text, "images": images, "hasVideo": bool(b.get("hasVideo")), "poll": poll,
            "circle": b.get("circle"), "topic": b.get("topic"), "likes": 0, "comments": 0,
            "status": "pending", "ts": int(time.time() * 1000)}
    db.data["posts"].append(post)
    db.save()
    return post


def h_feedback_list(q, _b, _p):
    uid = q.get("uid")
    out = [f for f in db.data["feedback"] if not uid or f["uid"] == uid]
    out.sort(key=lambda x: x["ts"], reverse=True)
    return out


def h_feedback_create(_q, b, _p):
    desc = str(b.get("desc", "")).strip()
    contact = str(b.get("contact", "")).strip()
    if not desc:
        raise ApiError(400, "请填写意见描述")
    if len(desc) > 500:
        raise ApiError(400, "描述不能超过 500 字")
    if not contact:
        raise ApiError(400, "请填写联系方式")
    fb = {"id": new_id("fb"), "uid": str(b.get("uid", "800123")), "cat": b.get("cat", "other"),
          "subject": str(b.get("subject", "")).strip()[:80], "desc": desc, "contact": contact,
          "images": list(b.get("images") or [])[:5], "ts": int(time.time() * 1000), "status": "new", "replies": []}
    db.data["feedback"].append(fb)
    db.save()
    return fb


def h_notifications(_q, _b, _p):
    return sorted(db.data["notifications"], key=lambda x: x["ts"], reverse=True)


def h_service_get(_q, _b, p):
    uid = p["uid"]
    msgs = db.data["service"].get(uid, [])
    cutoff = int(time.time() * 1000) - SERVICE_RETENTION_MS
    return [m for m in msgs if m["ts"] >= cutoff]


def h_service_send(_q, b, p):
    uid = p["uid"]
    kind = b.get("kind", "text")
    text = str(b.get("text", "")).strip()
    if kind == "text" and not text:
        raise ApiError(400, "消息不能为空")
    m = {"id": new_id("s"), "who": "user", "kind": kind, "text": text, "image": b.get("image", ""), "ts": int(time.time() * 1000)}
    db.data["service"].setdefault(uid, []).append(m)
    # Demo auto-reply so the flow is testable without an admin console
    reply = {"id": new_id("s"), "who": "agent", "kind": "text",
             "text": "您好，已收到您的消息，客服将尽快为您处理。工作时间：每天 10:00 – 18:00。", "ts": int(time.time() * 1000) + 1}
    db.data["service"][uid].append(reply)
    u = db.data["unread"].setdefault(uid, {"share": 0, "feedback": 0, "sysnotify": 0, "service": 0, "users": {}})
    u["service"] = u.get("service", 0) + 1
    db.save()
    return m


def h_service_recall(_q, _b, p):
    uid, mid = p["uid"], p["mid"]
    for m in db.data["service"].get(uid, []):
        if m["id"] == mid:
            if m["who"] != "user":
                raise ApiError(403, "只能撤回自己的消息")
            if int(time.time() * 1000) - m["ts"] > RECALL_WINDOW_MS:
                raise ApiError(400, "超过 3 分钟，无法撤回")
            m["kind"] = "recalled"
            m["text"] = ""
            db.save()
            return m
    raise ApiError(404, "message not found")


def h_chats(_q, _b, p):
    uid = p["uid"]
    convs = db.data["chats"].get(uid, {})
    out = []
    for peer, c in convs.items():
        msgs = c.get("msgs", [])
        last = msgs[-1] if msgs else None
        out.append({"peer": peer, "name": c.get("name", peer), "gender": c.get("gender", ""),
                    "preview": (last or {}).get("text", "") if (last or {}).get("kind") == "text" else ("[图片]" if last else ""),
                    "ts": (last or {}).get("ts", 0)})
    out.sort(key=lambda x: x["ts"], reverse=True)
    return out


def _chat(uid, peer):
    convs = db.data["chats"].setdefault(uid, {})
    return convs.setdefault(peer, {"name": peer, "gender": "", "msgs": []})


def h_chat_get(_q, _b, p):
    c = _chat(p["uid"], p["peer"])
    return {"peer": p["peer"], "name": c["name"], "gender": c.get("gender", ""), "msgs": c["msgs"],
            "locked": _chat_locked(p["uid"], c["msgs"])}


def _chat_locked(uid, msgs):
    """≤2 messages before the other side replies."""
    pending = 0
    for m in reversed(msgs):
        if m["from"] == uid:
            pending += 1
        else:
            break
    return pending >= CHAT_PRE_REPLY_MAX


def h_chat_send(_q, b, p):
    uid, peer = p["uid"], p["peer"]
    if peer == uid:
        raise ApiError(400, "不能给自己发私信")
    c = _chat(uid, peer)
    if _chat_locked(uid, c["msgs"]):
        raise ApiError(423, f"对方回复前最多发送 {CHAT_PRE_REPLY_MAX} 条消息")
    text = str(b.get("text", "")).strip()
    if not text:
        raise ApiError(400, "消息不能为空")
    m = {"id": new_id("c"), "from": uid, "kind": "text", "text": text, "ts": int(time.time() * 1000)}
    c["msgs"].append(m)
    db.save()
    return {"msg": m, "locked": _chat_locked(uid, c["msgs"])}


def h_unread(_q, _b, p):
    return db.data["unread"].get(p["uid"], {"share": 0, "feedback": 0, "sysnotify": 0, "service": 0, "users": {}})


def h_unread_clear(_q, b, p):
    u = db.data["unread"].setdefault(p["uid"], {"share": 0, "feedback": 0, "sysnotify": 0, "service": 0, "users": {}})
    key = b.get("key")
    if key == "user":
        u.setdefault("users", {})[b.get("peer", "")] = 0
    elif key in ("share", "feedback", "sysnotify", "service"):
        u[key] = 0
    db.save()
    return u


def _member(uid):
    m = db.data["members"].get(uid)
    if not m:
        raise ApiError(404, "member not found")
    return m


def h_profile(_q, _b, p):
    return _member(p["uid"])


def _review_used(uid):
    l = [r for r in db.data["profileReviews"] if r["uid"] == uid]
    core = sum(1 for r in l if r.get("core"))
    other = sum(1 for r in l if r.get("other"))
    return core, other


def h_reviews(_q, _b, p):
    uid = p["uid"]
    core, other = _review_used(uid)
    items = sorted([r for r in db.data["profileReviews"] if r["uid"] == uid], key=lambda x: x["at"], reverse=True)
    return {"left": {"core": max(0, CORE_MAX - core), "other": max(0, OTHER_MAX - other)},
            "max": {"core": CORE_MAX, "other": OTHER_MAX}, "items": items}


CORE_KEYS = ("avatar", "name", "gender")
OTHER_KEYS = ("bio", "bgUrl", "company", "job", "role", "wechat", "whatsapp", "fb", "ig")


def h_review_submit(_q, b, p):
    uid = p["uid"]
    m = _member(uid)
    core = {k: v for k, v in (b.get("core") or {}).items() if k in CORE_KEYS}
    other = {k: v for k, v in (b.get("other") or {}).items() if k in OTHER_KEYS}
    if not core and not other:
        raise ApiError(400, "资料没有变化")
    if "name" in core:
        nm = str(core["name"]).strip()
        units = sum(2 if ord(ch) > 0x2E7F else 1 for ch in nm)
        if not nm or units > 20:
            raise ApiError(400, "昵称长度超出限制（中文 ≤10 字 / 英文 ≤20 字符）")
    if "bio" in other and len(str(other["bio"])) > 100:
        raise ApiError(400, "自我介绍不能超过 100 字")
    used_core, used_other = _review_used(uid)
    if core and used_core >= CORE_MAX:
        raise ApiError(400, "头像 / 用户名 / 性别修改次数已用完")
    if other and used_other >= OTHER_MAX:
        raise ApiError(400, "其它资料修改次数已用完")
    r = {"id": new_id("pr"), "uid": uid, "name": m["name"], "at": int(time.time() * 1000), "status": "pending",
         "core": core, "other": other, "reviewedAt": None, "note": ""}
    db.data["profileReviews"].append(r)
    db.save()
    return r


def h_review_decide(_q, b, p):
    """Admin decision (demo). status: approved | rejected | deleted"""
    status = b.get("status")
    if status not in ("approved", "rejected", "deleted"):
        raise ApiError(400, "bad status")
    for r in db.data["profileReviews"]:
        if r["id"] == p["id"]:
            r["status"] = status
            r["reviewedAt"] = int(time.time() * 1000)
            r["note"] = b.get("note", "")
            if status == "approved":
                m = _member(r["uid"])
                for k, v in r["core"].items():
                    m[k] = v
                for k, v in r["other"].items():
                    if k in ("bio", "bgUrl"):
                        m[k] = v
                    else:
                        m.setdefault("fields", {})[k] = v
                m["modifiedAt"] = r["reviewedAt"]
            db.save()
            return r
    raise ApiError(404, "review not found")


def h_admin_posts(_q, _b, _p):
    return sorted(db.data["posts"], key=lambda x: x["ts"], reverse=True)


def h_admin_post_decide(_q, b, p):
    status = b.get("status")
    if status not in ("approved", "rejected", "deleted"):
        raise ApiError(400, "bad status")
    for post in db.data["posts"]:
        if post["id"] == p["id"]:
            post["status"] = status
            db.save()
            return post
    raise ApiError(404, "post not found")


ROUTES = [
    ("GET", "/api/health", h_health),
    ("GET", "/api/home", h_home),
    ("GET", "/api/circles", h_circles),
    ("GET", "/api/topics", h_topics),
    ("GET", "/api/legal/{key}", h_legal),
    ("GET", "/api/events", h_events),
    ("POST", "/api/events", h_event_submit),
    ("GET", "/api/events/{id}", h_event),
    ("POST", "/api/events/{id}/view", h_event_view),
    ("POST", "/api/events/{id}/join", h_event_join),
    ("GET", "/api/posts", h_posts),
    ("POST", "/api/posts", h_post_create),
    ("GET", "/api/feedback", h_feedback_list),
    ("POST", "/api/feedback", h_feedback_create),
    ("GET", "/api/notifications", h_notifications),
    ("GET", "/api/service/{uid}", h_service_get),
    ("POST", "/api/service/{uid}", h_service_send),
    ("POST", "/api/service/{uid}/recall/{mid}", h_service_recall),
    ("GET", "/api/chats/{uid}", h_chats),
    ("GET", "/api/chats/{uid}/{peer}", h_chat_get),
    ("POST", "/api/chats/{uid}/{peer}", h_chat_send),
    ("GET", "/api/unread/{uid}", h_unread),
    ("POST", "/api/unread/{uid}/clear", h_unread_clear),
    ("GET", "/api/profile/{uid}", h_profile),
    ("GET", "/api/profile/{uid}/reviews", h_reviews),
    ("POST", "/api/profile/{uid}/reviews", h_review_submit),
    ("POST", "/api/admin/reviews/{id}/decide", h_review_decide),
    ("GET", "/api/admin/posts", h_admin_posts),
    ("POST", "/api/admin/posts/{id}/decide", h_admin_post_decide),
]


def match(method, path):
    parts = [s for s in path.split("/") if s]
    for m, pat, fn in ROUTES:
        if m != method:
            continue
        pp = [s for s in pat.split("/") if s]
        if len(pp) != len(parts):
            continue
        params = {}
        ok = True
        for a, b in zip(pp, parts):
            if a.startswith("{"):
                params[a[1:-1]] = b
            elif a != b:
                ok = False
                break
        if ok:
            return fn, params
    return None, None


class Handler(BaseHTTPRequestHandler):
    server_version = "CampusCircleAPI/1.0"

    def log_message(self, fmt, *args):
        pass

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")

    def _json(self, status, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self._cors()
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def _dispatch(self, method):
        u = urlparse(self.path)
        fn, params = match(method, u.path)
        if not fn:
            return self._json(404, {"error": "not found"})
        q = {k: v[0] for k, v in parse_qs(u.query).items()}
        body = {}
        if method == "POST":
            n = int(self.headers.get("Content-Length") or 0)
            raw = self.rfile.read(n) if n else b""
            if raw:
                try:
                    body = json.loads(raw.decode("utf-8"))
                except Exception:
                    return self._json(400, {"error": "invalid json"})
        try:
            with LOCK:
                result = fn(q, body, params)
            self._json(200, {"data": result})
        except ApiError as e:
            self._json(e.status, {"error": e.msg})
        except Exception as e:  # noqa
            self._json(500, {"error": str(e)})

    def do_GET(self):
        self._dispatch("GET")

    def do_POST(self):
        self._dispatch("POST")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8787)
    ap.add_argument("--host", default="0.0.0.0")
    a = ap.parse_args()
    srv = ThreadingHTTPServer((a.host, a.port), Handler)
    print(f"Campus Circle API listening on http://{a.host}:{a.port}  (db: {DB_PATH})")
    srv.serve_forever()


if __name__ == "__main__":
    main()
